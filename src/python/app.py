#!/usr/bin/env python3

import pyforms
from pyforms.basewidget import BaseWidget
from pyforms.controls import ControlText
from pyforms.controls import ControlButton

# https://pyforms.readthedocs.io/en/v4/
# https://pyforms-gui.readthedocs.io/en/v4/getting-started/the-basic.html

class SimpleExample1(BaseWidget):
    def __init__(self):
        super(SimpleExample1, self).__init__('Simple Example 1')

        self._firstname  = ControlText('First name', 'Default value')
        self._middlename = ControlText('Middle name')
        self._lastname   = ControlText('Lastname name')
        self._fullname   = ControlText('Full name')
        self._button     = ControlButton('Press this button')

if __name__ == "__main__":
    pyforms.start_app(SimpleExample1)
