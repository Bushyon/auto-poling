import tkinter as tk
import subprocess

def install(min, max, update):
    
    # Define the command to run
    command = ['./install.sh', '--min', str(min), '--max', str(max), '--update', str(update)]

    # Run the command
    process = subprocess.run(command)

    # Check the return code to see if the command was successful
    if process.returncode == 0:
        print("Installation successful!")
    else:
        print("Installation failed. Please check your parameters.")

def uninstall():
    # Define the command to run
    command = ['./uninstall.sh']

    # Run the command
    process = subprocess.run(command)

    # Check the return code to see if the command was successful
    if process.returncode == 0:
        print("Uninstalled successfully!")
    else:
        print("Removal failed. Please check your parameters.")

def set_polling_rate():
    # Remove any existing error label
    for widget in root.winfo_children():
        if isinstance(widget, tk.Label) and widget.cget("text") == "All of the values should be integers.":
            widget.destroy()
    try:
        min_rate = int(min_entry.get())
        max_rate = int(max_entry.get())
        update_interval = int(interval_entry.get())
        print(f"Minimum Polling Rate: {min_rate}, Maximum Polling Rate: {max_rate}, Update Interval: {update_interval}")
        uninstall()
        install(min_rate,max_rate,update_interval)
    except ValueError:
        # Display error label
        result_label = tk.Label(root, text="All of the values should be integers.", font=("Helvetica", 12), fg="red")
        result_label.grid(row=4, column=0, columnspan=2, pady=(10, 0))


if __name__ == "__main__":
    # Create the main window
    root = tk.Tk()
    root.title("Auto-Poling Configurator")

    frame = tk.Frame(root)
    frame.grid(row=0, column=0, sticky="nsew", padx=200, pady=200)  # Added padx and pady for padding

    # Labels and Entry Fields
    tk.Label(frame, text="Minimum Polling Rate:").grid(row=0, column=0, sticky="e")  # Added pady for spacing
    min_entry = tk.Entry(frame)
    min_entry.grid(row=0, column=1, sticky="w")

    tk.Label(frame, text="Maximum Polling Rate:").grid(row=1, column=0, sticky="e")
    max_entry = tk.Entry(frame)
    max_entry.grid(row=1, column=1, sticky="w")

    tk.Label(frame, text="Update Interval (seconds):").grid(row=2, column=0, sticky="e")
    interval_entry = tk.Entry(frame)
    interval_entry.grid(row=2, column=1, sticky="w")

    set_button = tk.Button(frame, text="Set Polling Rate", command=set_polling_rate)
    set_button.grid(row=3, column=0, columnspan=2, pady=(10, 0))

    root.grid_rowconfigure(0, weight=1)
    root.grid_columnconfigure(0, weight=1)

    frame.grid_rowconfigure((0, 1, 2), weight=1)
    frame.grid_columnconfigure((0, 1), weight=1)

    root.mainloop()
