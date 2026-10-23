
import tkinter as tk
from tkinter import messagebox
from calculator_bridge import calculate

# ============================================================
# THEME
# ============================================================

BG = "#0B1120"
PANEL = "#131D2E"
INPUT_BG = "#0A1525"
ACCENT = "#27D3B5"
TEXT = "#E7EEF8"
MUTED = "#8494AA"
RED = "#FF657A"
GREEN = "#55E6A5"
BORDER = "#26364B"
ACTIVE_BG = "#123E49"
FONT = "Consolas"

STATE_NAMES = {
    0: "IDLE",
    1: "EXECUTE",
    2: "DONE",
    3: "ERROR",
    4: "WAIT_RELEASE",
}

STATE_DESCRIPTIONS = {
    0: "Waiting for a request",
    1: "Processing the operation",
    2: "Operation completed",
    3: "RTL error detected",
    4: "Waiting for start release",
}

STATE_COLORS = {
    0: "#77A7FF",
    1: ACCENT,
    2: GREEN,
    3: RED,
    4: "#C49BFF",
}

SYMBOLS = ["+", "−", "×", "÷"]
OPERATIONS = [
    "ADDITION", "SUBTRACTION", "MULTIPLICATION", "DIVISION"
]

# ============================================================
# WINDOW
# ============================================================

root = tk.Tk()
root.title("RTL Calculator | Silicon Lab")
root.geometry("1250x800")
root.minsize(900, 650)
root.configure(bg=BG)

selected_op = tk.IntVar(value=0)

animation_job = None
animation_token = 0
animation_states = []
animation_index = 0
fsm_current_state = None

# ============================================================
# MAIN GRID
# ============================================================

root.grid_columnconfigure(0, weight=1)
root.grid_rowconfigure(1, weight=1)

header = tk.Frame(root, bg=BG)
header.grid(row=0, column=0, sticky="ew", padx=22, pady=(12, 10))

tk.Label(
    header, text="SILICON LAB  /  DIGITAL DESIGN",
    bg=BG, fg=ACCENT, font=(FONT, 9, "bold")
).pack(anchor="w")

tk.Label(
    header, text="RTL CALCULATOR",
    bg=BG, fg=TEXT, font=(FONT, 22, "bold")
).pack(anchor="w", pady=(5, 2))

tk.Label(
    header,
    text="SYSTEMVERILOG  •  VIVADO XSIM  •  PYTHON INTERFACE",
    bg=BG, fg=MUTED, font=(FONT, 9)
).pack(anchor="w")

# Main content: left calculator and right FSM.
main = tk.Frame(root, bg=BG)
main.grid(row=1, column=0, sticky="nsew", padx=18, pady=(0, 12))

main.grid_columnconfigure(0, weight=5, uniform="main")
main.grid_columnconfigure(1, weight=6, uniform="main")
main.grid_rowconfigure(0, weight=1)

left = tk.Frame(main, bg=BG)
left.grid(row=0, column=0, sticky="nsew", padx=(0, 8))

right = tk.Frame(main, bg=BG)
right.grid(row=0, column=1, sticky="nsew", padx=(8, 0))

# ============================================================
# LEFT: CALCULATOR
# ============================================================

input_panel = tk.Frame(left, bg=PANEL)
input_panel.pack(fill="x", expand=True)

tk.Label(
    input_panel, text="INPUT OPERANDS  /  4-BIT UNSIGNED",
    bg=PANEL, fg=MUTED, font=(FONT, 9)
).pack(anchor="w", padx=18, pady=(18, 14))

operand_row = tk.Frame(input_panel, bg=PANEL)
operand_row.pack(fill="x", padx=18)
operand_row.grid_columnconfigure((0, 1), weight=1, uniform="operand")


def create_operand(parent, title, column, value):
    frame = tk.Frame(parent, bg=PANEL)
    frame.grid(row=0, column=column, sticky="ew",
               padx=(0, 6) if column == 0 else (6, 0))

    tk.Label(
        frame, text=title, bg=PANEL, fg=ACCENT,
        font=(FONT, 9)
    ).pack(anchor="w", pady=(0, 7))

    entry = tk.Entry(
        frame, bg=INPUT_BG, fg=TEXT,
        insertbackground=ACCENT, justify="center",
        font=(FONT, 19, "bold"), relief="flat",
        highlightthickness=1, highlightbackground=BORDER,
        highlightcolor=ACCENT
    )
    entry.pack(fill="x", ipady=9)
    entry.insert(0, value)
    return entry


entry_a = create_operand(operand_row, "OPERAND A", 0, "3")
entry_b = create_operand(operand_row, "OPERAND B", 1, "5")

tk.Label(
    input_panel, text="ARITHMETIC UNIT  /  SELECT OPERATION",
    bg=PANEL, fg=MUTED, font=(FONT, 9)
).pack(anchor="w", padx=18, pady=(22, 10))

operation_grid = tk.Frame(input_panel, bg=PANEL)
operation_grid.pack(fill="x", padx=18)
operation_grid.grid_columnconfigure((0, 1), weight=1, uniform="op")

operation_buttons = []


def choose_operation(op):
    selected_op.set(op)
    for i, button in enumerate(operation_buttons):
        active = (i == op)
        button.configure(
            bg=ACCENT if active else INPUT_BG,
            fg=BG if active else TEXT
        )


for i, (symbol, name) in enumerate(zip(SYMBOLS, OPERATIONS)):
    button = tk.Button(
        operation_grid,
        text=f"{symbol}  {name}",
        command=lambda op=i: choose_operation(op),
        bg=INPUT_BG, fg=TEXT,
        activebackground=ACTIVE_BG, activeforeground=TEXT,
        font=(FONT, 9, "bold"), relief="flat",
        cursor="hand2", pady=12, bd=0
    )
    button.grid(
        row=i // 2, column=i % 2, sticky="ew",
        padx=4, pady=4
    )
    operation_buttons.append(button)

choose_operation(0)

# Result display
result_panel = tk.Frame(left, bg=INPUT_BG)
result_panel.pack(fill="x", pady=(10, 0))

tk.Label(
    result_panel, text="SIMULATED HARDWARE OUTPUT",
    bg=INPUT_BG, fg=MUTED, font=(FONT, 9)
).pack(anchor="w", padx=18, pady=(14, 2))

result_value = tk.Label(
    result_panel, text="—",
    bg=INPUT_BG, fg=GREEN, font=(FONT, 30, "bold")
)
result_value.pack(anchor="w", padx=18)

expression_value = tk.Label(
    result_panel, text="Ready for RTL simulation",
    bg=INPUT_BG, fg=TEXT, font=(FONT, 10)
)
expression_value.pack(anchor="w", padx=18, pady=(0, 8))

remainder_row = tk.Frame(result_panel, bg=INPUT_BG)

tk.Label(
    remainder_row, text="REMAINDER",
    bg=INPUT_BG, fg=MUTED, font=(FONT, 9)
).pack(side="left")

remainder_value = tk.Label(
    remainder_row, text="—",
    bg=INPUT_BG, fg=ACCENT, font=(FONT, 10, "bold")
)
remainder_value.pack(side="left", padx=(10, 0))

# Run button
calculate_button = tk.Button(
    left, text="RUN RTL CALCULATION",
    command=lambda: run_calculation(),
    bg=ACCENT, fg=BG,
    activebackground=ACCENT, activeforeground=BG,
    font=(FONT, 10, "bold"), relief="flat",
    cursor="hand2", pady=15, bd=0
)
calculate_button.pack(fill="x", pady=(10, 6))

status_label = tk.Label(
    left, text="READY  |  WAITING FOR INPUT",
    bg=BG, fg=MUTED, font=(FONT, 9, "bold"),
    wraplength=480
)
status_label.pack(anchor="w", pady=(3, 0))

# ============================================================
# RIGHT: FSM DIAGRAM
# ============================================================

fsm_panel = tk.Frame(right, bg=PANEL)
fsm_panel.pack(fill="both", expand=True)

fsm_header = tk.Frame(fsm_panel, bg=PANEL)
fsm_header.pack(fill="x", padx=16, pady=(16, 3))

tk.Label(
    fsm_header, text="FINITE STATE MACHINE",
    bg=PANEL, fg=TEXT, font=(FONT, 12, "bold")
).pack(side="left")

tk.Label(
    fsm_header, text="XSim TRACE",
    bg=PANEL, fg=ACCENT, font=(FONT, 8, "bold")
).pack(side="right")

tk.Label(
    fsm_panel,
    text="Actual state sequence recorded by SystemVerilog",
    bg=PANEL, fg=MUTED, font=(FONT, 8),
    wraplength=500, justify="left"
).pack(anchor="w", padx=16, pady=(2, 8))

fsm_canvas = tk.Canvas(
    fsm_panel, bg=PANEL,
    highlightthickness=0, bd=0, height=330
)
fsm_canvas.pack(fill="both", expand=True, padx=5, pady=2)

fsm_detail = tk.Label(
    fsm_panel, text="Waiting for simulation",
    bg=PANEL, fg=MUTED, font=(FONT, 9, "bold"),
    wraplength=500, justify="left"
)
fsm_detail.pack(anchor="w", padx=16, pady=(6, 4))

fsm_progress = tk.Label(
    fsm_panel, text="NO TRANSITIONS RECORDED",
    bg=PANEL, fg=MUTED, font=(FONT, 8, "bold")
)
fsm_progress.pack(anchor="w", padx=16, pady=(2, 16))

state_node_ids = {}
state_text_ids = {}
state_number_ids = {}

# Relative positions allow the diagram to resize with the window.
STATE_POSITIONS = {
    0: (0.15, 0.22),  # IDLE
    1: (0.51, 0.22),  # EXECUTE
    2: (0.84, 0.17),  # DONE
    3: (0.84, 0.49),  # ERROR
    4: (0.51, 0.78),  # WAIT_RELEASE
}


def draw_fsm(event=None):
    fsm_canvas.delete("all")
    state_node_ids.clear()
    state_text_ids.clear()
    state_number_ids.clear()

    width = max(fsm_canvas.winfo_width(), 400)
    height = max(fsm_canvas.winfo_height(), 300)

    points = {
        code: (x * width, y * height)
        for code, (x, y) in STATE_POSITIONS.items()
    }

    # Transitions shown by the FSM.
    connections = [
        (0, 1), (1, 2), (1, 3),
        (2, 4), (3, 4), (4, 0)
    ]

    for source, target in connections:
        x1, y1 = points[source]
        x2, y2 = points[target]

        dx, dy = x2 - x1, y2 - y1
        distance = max((dx * dx + dy * dy) ** 0.5, 1)
        ux, uy = dx / distance, dy / distance
        radius = 45

        fsm_canvas.create_line(
            x1 + ux * radius, y1 + uy * radius,
            x2 - ux * radius, y2 - uy * radius,
            fill=BORDER, width=2,
            arrow=tk.LAST, arrowshape=(8, 10, 4)
        )

    for code, (x, y) in points.items():
        name = STATE_NAMES[code]
        node_color = STATE_COLORS[code]

        node = fsm_canvas.create_oval(
            x - 48, y - 29, x + 48, y + 29,
            fill=INPUT_BG, outline=BORDER, width=2
        )

        label = fsm_canvas.create_text(
            x, y - 4, text=name,
            fill=TEXT, font=(FONT, 8, "bold")
        )

        number = fsm_canvas.create_text(
            x, y + 13, text=f"STATE {code}",
            fill=MUTED, font=(FONT, 7)
        )

        state_node_ids[code] = node
        state_text_ids[code] = label
        state_number_ids[code] = number

    highlight_state(fsm_current_state)


def highlight_state(code):
    global fsm_current_state
    fsm_current_state = code

    for state_code, node in state_node_ids.items():
        active = (state_code == code)
        color = STATE_COLORS[state_code]

        fsm_canvas.itemconfigure(
            node,
            fill=(
                "#482632" if active and state_code == 3
                else ACTIVE_BG if active
                else INPUT_BG
            ),
            outline=color if active else BORDER,
            width=3 if active else 2
        )

        fsm_canvas.itemconfigure(
            state_text_ids[state_code],
            fill=color if active else TEXT
        )

        fsm_canvas.itemconfigure(
            state_number_ids[state_code],
            fill=TEXT if active else MUTED
        )

    if code in STATE_NAMES:
        fsm_detail.configure(
            text=f"ACTIVE: {STATE_NAMES[code]}  |  "
                 f"{STATE_DESCRIPTIONS[code]}",
            fg=STATE_COLORS[code]
        )
    elif code is None:
        fsm_detail.configure(
            text="Waiting for recorded state transitions",
            fg=MUTED
        )


fsm_canvas.bind("<Configure>", draw_fsm)

# ============================================================
# BOTTOM: EXECUTION MONITOR AND RAW LOG
# ============================================================

monitor = tk.Frame(root, bg=PANEL)
monitor.grid(row=2, column=0, sticky="ew", padx=18, pady=(0, 12))
monitor.grid_columnconfigure(0, weight=1)

monitor_top = tk.Frame(monitor, bg=PANEL)
monitor_top.pack(fill="x", padx=16, pady=(10, 5))

tk.Label(
    monitor_top, text="EXECUTION MONITOR",
    bg=PANEL, fg=TEXT, font=(FONT, 10, "bold")
).pack(side="left")

tk.Label(
    monitor_top,
    text="AMD VIVADO XSIM  •  calculator_top.sv",
    bg=PANEL, fg=ACCENT, font=(FONT, 8)
).pack(side="right")

log_frame = tk.Frame(monitor, bg=INPUT_BG)
log_frame.pack(fill="x", padx=16, pady=(0, 12))

log_scrollbar = tk.Scrollbar(log_frame)
log_scrollbar.pack(side="right", fill="y")

simulator_log = tk.Text(
    log_frame, height=5,
    bg=INPUT_BG, fg=TEXT,
    insertbackground=ACCENT,
    font=(FONT, 8), relief="flat",
    wrap="word", padx=10, pady=8,
    yscrollcommand=log_scrollbar.set,
    state="disabled"
)
simulator_log.pack(side="left", fill="both", expand=True)
log_scrollbar.configure(command=simulator_log.yview)


def show_simulator_log(text):
    simulator_log.configure(state="normal")
    simulator_log.delete("1.0", "end")
    simulator_log.insert("1.0", text)
    simulator_log.see("end")
    simulator_log.configure(state="disabled")


# ============================================================
# FSM ANIMATION
# ============================================================

def stop_fsm_animation():
    global animation_job, animation_token

    animation_token += 1

    if animation_job is not None:
        try:
            root.after_cancel(animation_job)
        except tk.TclError:
            pass

    animation_job = None


def animate_transitions(transitions):
    global animation_states, animation_index, animation_job

    stop_fsm_animation()
    token = animation_token

    animation_states = list(transitions or [])
    animation_index = 0

    if not animation_states:
        highlight_state(None)
        fsm_detail.configure(
            text="No FSM transitions returned by XSim",
            fg=RED
        )
        fsm_progress.configure(
            text="TRACE UNAVAILABLE",
            fg=RED
        )
        return

    highlight_state(None)

    fsm_progress.configure(
        text=f"RECORDED STATES: {len(animation_states)}",
        fg=ACCENT
    )

    def show_next():
        global animation_index, animation_job

        if token != animation_token:
            return

        if animation_index >= len(animation_states):
            animation_job = None
            return

        item = animation_states[animation_index]

        if isinstance(item, dict):
            code = item.get("code")
        else:
            code = int(item)

        if code not in STATE_NAMES:
            fsm_detail.configure(
                text=f"Unknown state code: {code}",
                fg=RED
            )
            animation_job = None
            return

        highlight_state(code)

        fsm_progress.configure(
            text=f"STATE {animation_index + 1} / "
                 f"{len(animation_states)}  •  "
                 f"{STATE_NAMES[code]}",
            fg=STATE_COLORS[code]
        )

        animation_index += 1
        animation_job = root.after(700, show_next)

    show_next()


# ============================================================
# CALCULATION HANDLER
# ============================================================

def run_calculation():
    try:
        a_text = entry_a.get().strip()
        b_text = entry_b.get().strip()

        if not a_text.isdigit() or not b_text.isdigit():
            raise ValueError("Enter whole numbers from 0 to 15.")

        a, b = int(a_text), int(b_text)
        op = selected_op.get()

        if not (0 <= a <= 15 and 0 <= b <= 15):
            raise ValueError("Inputs A and B must be between 0 and 15.")

        stop_fsm_animation()
        highlight_state(None)

        calculate_button.configure(
            text="SIMULATING RTL...", state="disabled"
        )
        status_label.configure(
            text="RUNNING VIVADO XSIM...", fg=ACCENT
        )

        show_simulator_log(
            "Vivado XSim is running...\n"
            "Waiting for the SystemVerilog RTL response."
        )

        fsm_progress.configure(
            text="SIMULATION IN PROGRESS", fg=ACCENT
        )

        root.update_idletasks()

        # Actual arithmetic is performed by SystemVerilog RTL.
        response = calculate(a, b, op)

        show_simulator_log(response["simulator_output"])

        result = response["result"]
        remainder = response["remainder"]
        done = response["done"]
        error = response["error"]

        result_value.configure(
            text=str(result),
            fg=GREEN if done and not error else RED
        )

        expression_value.configure(
            text=f"{a} {SYMBOLS[op]} {b} = {result}"
        )

        if op == 3:
            remainder_value.configure(
                text="—" if error else str(remainder)
            )
            remainder_row.pack(
                anchor="w", padx=18, pady=(0, 12)
            )
        else:
            remainder_row.pack_forget()

        status_label.configure(
            text=f"RTL COMPLETE  |  DONE={done}  |  ERROR={error}",
            fg=GREEN if done and not error else RED
        )

        animate_transitions(response.get("transitions", []))

    except ValueError as exc:
        messagebox.showwarning("Invalid input", str(exc))

    except Exception as exc:
        result_value.configure(text="ERROR", fg=RED)
        status_label.configure(text="SIMULATION FAILED", fg=RED)
        show_simulator_log(str(exc))

        fsm_detail.configure(
            text="Unable to obtain FSM trace",
            fg=RED
        )
        fsm_progress.configure(
            text="SIMULATION / TRACE ERROR",
            fg=RED
        )

        messagebox.showerror("Vivado XSim error", str(exc))

    finally:
        calculate_button.configure(
            text="RUN RTL CALCULATION", state="normal"
        )


# ============================================================
# FOOTER
# ============================================================

footer = tk.Label(
    root,
    text="PYTHON: GUI AND PROCESS CONTROL  |  XSIM: RTL SIMULATION",
    bg=BG, fg=MUTED, font=(FONT, 8)
)
footer.grid(row=3, column=0, sticky="ew", pady=(0, 8))

root.after(200, draw_fsm)
root.mainloop()
