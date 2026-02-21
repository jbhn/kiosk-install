import tkinter as tk

root = tk.Tk()
root.attributes("-fullscreen", True)
root.configure(bg="black")

label = tk.Label(
    root,
    text="TRS1 PANEL",
    font=("Helvetica", 48),
    fg="white",
    bg="black"
)
label.pack(expand=True)

root.mainloop()
