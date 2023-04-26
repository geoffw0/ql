# Here we test writing to a captured variable via the `nonlocal` keyword (see `out`).
# We also test reading one captured variable and writing the value to another (see `through`).

# All functions starting with "test_" should run and execute `print("OK")` exactly once.
# This can be checked by running validTest.py.

import sys
import os

sys.path.append(os.path.dirname(os.path.dirname((__file__))))
from testlib import expects

# These are defined so that we can evaluate the test code.
NONSOURCE = "not a source"
SOURCE = "source"

def is_source(x):
    return x == "source" or x == b"source" or x == 42 or x == 42.0 or x == 42j


def SINK(x):
    if is_source(x):
        print("OK")
    else:
        print("Unexpected flow", x)


def SINK_F(x):
    if is_source(x):
        print("Unexpected flow", x)
    else:
        print("OK")


sinkO1 = ""
sinkO2 = ""
nonSink0 = ""

def out():
    def captureOut1():
        global sinkO1
        sinkO1 = SOURCE
    captureOut1()
    SINK(sinkO1) #$ captured

    def captureOut2():
        def m():
            global sinkO2
            sinkO2 = SOURCE
        m()
    captureOut2()
    SINK(sinkO2) #$ captured

    def captureOut1NotCalled():
        global nonSink0
        nonSink0 = SOURCE
    SINK_F(nonSink0) #$ SPURIOUS: captured

    def captureOut2NotCalled():
        def m():
            global nonSink0
            nonSink0 = SOURCE
    captureOut2NotCalled()
    SINK_F(nonSink0) #$ SPURIOUS: captured

@expects(4)
def test_out():
    out()

sinkT1 = ""
sinkT2 = ""
nonSinkT0 = ""
def through(tainted):
    def captureOut1():
        global sinkT1
        sinkT1 = tainted
    captureOut1()
    SINK(sinkT1) #$ MISSING:captured

    def captureOut2():
        def m():
            global sinkT2
            sinkT2 = tainted
        m()
    captureOut2()
    SINK(sinkT2) #$ MISSING:captured

    def captureOut1NotCalled():
        global nonSinkT0
        nonSinkT0 = tainted
    SINK_F(nonSinkT0)

    def captureOut2NotCalled():
        def m():
            global nonSinkT0
            nonSinkT0 = tainted
    captureOut2NotCalled()
    SINK_F(nonSinkT0)

@expects(4)
def test_through():
    through(SOURCE)
