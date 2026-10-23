
import subprocess
from pathlib import Path

# ---------- Project Paths ----------
SIM_DIR = Path(r"E:\VLSI_Practice\Calculator_GUI\sim")
XSIM = Path(r"F:\2025.2\Vivado\bin\xsim.bat")

REQUEST_FILE = SIM_DIR / "request.txt"
RESPONSE_FILE = SIM_DIR / "response.txt"
TRANSITIONS_FILE = SIM_DIR / "fsm_transitions.txt"

SNAPSHOT = "calculator_gui_snapshot"

STATE_NAMES = {
    0: "IDLE",
    1: "EXECUTE",
    2: "DONE",
    3: "ERROR",
    4: "WAIT_RELEASE",
}


def calculate(a, b, op):
    """Run the actual SystemVerilog calculator through Vivado XSim."""

    if not (0 <= a <= 15 and 0 <= b <= 15):
        raise ValueError("A and B must be between 0 and 15.")

    if op not in (0, 1, 2, 3):
        raise ValueError("Operation must be between 0 and 3.")

    # Write the request for the SystemVerilog testbench.
    REQUEST_FILE.write_text(
        f"{a} {b} {op}\n",
        encoding="utf-8"
    )

    # Remove stale outputs before starting this simulation.
    RESPONSE_FILE.unlink(missing_ok=True)
    TRANSITIONS_FILE.unlink(missing_ok=True)

    command = f"call {XSIM} {SNAPSHOT} -runall"

    try:
        process = subprocess.run(
            ["cmd.exe", "/d", "/c", command],
            cwd=str(SIM_DIR),
            capture_output=True,
            text=True,
            timeout=30
        )
    except subprocess.TimeoutExpired as exc:
        raise RuntimeError(
            "Vivado XSim timed out after 30 seconds."
        ) from exc

    simulator_output = (
        (process.stdout or "")
        + "\n"
        + (process.stderr or "")
    )

    if process.returncode != 0:
        raise RuntimeError(
            "Vivado XSim failed:\n" + simulator_output
        )

    if not RESPONSE_FILE.exists():
        raise RuntimeError(
            "XSim did not create response.txt.\n"
            + simulator_output
        )

    values = RESPONSE_FILE.read_text(
        encoding="utf-8"
    ).split()

    if len(values) != 4:
        raise RuntimeError(
            f"Invalid response from RTL: {values}\n"
            + simulator_output
        )

    result, remainder, done, error = map(int, values)

    if not done and not error:
        raise RuntimeError(
            "The RTL neither completed nor reported an error.\n"
            + simulator_output
        )

    # Read the states recorded by the SystemVerilog testbench.
    if not TRANSITIONS_FILE.exists():
        raise RuntimeError(
            "XSim did not create fsm_transitions.txt.\n"
            + simulator_output
        )

    try:
        state_codes = [
            int(line.strip())
            for line in TRANSITIONS_FILE.read_text(
                encoding="utf-8"
            ).splitlines()
            if line.strip()
        ]
        transitions = [
            {
                "code": code,
                "name": STATE_NAMES[code],
            }
            for code in state_codes
        ]
    except (ValueError, KeyError) as exc:
        raise RuntimeError(
            "Invalid FSM state data in fsm_transitions.txt."
        ) from exc

    # Convert 8-bit two's-complement subtraction output to signed.
    if op == 1 and result >= 128:
        result -= 256

    return {
        "result": result,
        "remainder": remainder,
        "done": done,
        "error": error,
        "simulator_output": simulator_output,
        "transitions": transitions,
    }


# ---------- Optional Command-Line Verification ----------
# This runs only when the bridge is launched directly.
# It does not create a verification panel in the GUI.

if __name__ == "__main__":
    tests = [
        {
            "a": 3, "b": 5, "op": 0,
            "name": "Addition",
            "expected_result": 8,
            "expected_remainder": 0,
            "expected_done": 1,
            "expected_error": 0,
        },
        {
            "a": 9, "b": 4, "op": 1,
            "name": "Subtraction",
            "expected_result": 5,
            "expected_remainder": 0,
            "expected_done": 1,
            "expected_error": 0,
        },
        {
            "a": 3, "b": 4, "op": 2,
            "name": "Multiplication",
            "expected_result": 12,
            "expected_remainder": 0,
            "expected_done": 1,
            "expected_error": 0,
        },
        {
            "a": 13, "b": 4, "op": 3,
            "name": "Division with remainder",
            "expected_result": 3,
            "expected_remainder": 1,
            "expected_done": 1,
            "expected_error": 0,
        },
        {
            "a": 15, "b": 15, "op": 2,
            "name": "Maximum multiplication",
            "expected_result": 225,
            "expected_remainder": 0,
            "expected_done": 1,
            "expected_error": 0,
        },
        {
            "a": 13, "b": 0, "op": 3,
            "name": "Division by zero",
            "expected_result": None,
            "expected_remainder": None,
            "expected_done": 0,
            "expected_error": 1,
        },
    ]

    passed = 0
    failed = 0

    print("\n=== VIVADO XSIM RTL VERIFICATION ===\n")

    for test in tests:
        try:
            response = calculate(
                test["a"],
                test["b"],
                test["op"]
            )

            checks = [
                response["done"] == test["expected_done"],
                response["error"] == test["expected_error"],
            ]

            if test["expected_result"] is not None:
                checks.extend([
                    response["result"] == test["expected_result"],
                    response["remainder"] == test["expected_remainder"],
                ])

            success = all(checks)
            status = "PASS" if success else "FAIL"

            print(
                f"{status}: {test['name']} | "
                f"A={test['a']} B={test['b']} "
                f"OP={test['op']} | "
                f"Result={response['result']} "
                f"Remainder={response['remainder']} "
                f"DONE={response['done']} "
                f"ERROR={response['error']}"
            )

            if success:
                passed += 1
            else:
                failed += 1

        except Exception as exc:
            failed += 1
            print(f"FAIL: {test['name']} | {exc}")

    print("\n-----------------------------------")
    print(f"Tests passed: {passed}")
    print(f"Tests failed: {failed}")
    print("-----------------------------------")

    if failed == 0:
        print("ALL TESTS PASSED!")
    else:
        print("VERIFICATION FAILED: CHECK RTL AND LOGS.")
