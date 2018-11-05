from tkinter import *
from tkinter import filedialog
from tkinter.ttk import *

root = Tk()
root.attributes("-topmost", True)
root.title('Tumblr Archive Downloader')

root.geometry("300x300")

def file_save():
    root.filename = filedialog.asksaveasfilename(initialdir="/", title="Select file", filetypes = (("jpeg files","*.jpg"),("all files","*.*")))
    print(root.filename)

def choose_dir():
    root.directory = filedialog.askdirectory(initialdir='..')
    if dir is None:
        return
    print(root.directory)

def webstuff():
    return 0

# button = Button(root, text='Save As', width=25, command=file_save)
dir_button = Button(root, text='Directory Select', width=25, command=choose_dir)

# button.pack()
dir_button.pack()

web_button = Button(root, text="Test Web Connections", width=25, command=webstuff)

web_button.pack()

# progress = Progressbar(root, orient="horizontal", length=200, mode="determinate")
#
# progress.pack()
#
# bar_button = Button(root, text="Test Progress Bar", width=25, command=bar)
#
# bar_button.pack()

root.mainloop()
