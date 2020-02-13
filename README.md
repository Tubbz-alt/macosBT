# OSX RFcomm wrapper for C++

This is a small helper / code demo which connects to a paired RFCOMM bluetooth device. It expects the RFCOMM device as
the 1st paired device.

It then starts a thread, connects to the device and prints the received data continously on the screen.

`main.cpp` is the main program written in C++. The C++ class `MacosBT` has a pure C++ header and only `MacosBT` is written in mixed C++ and ObjectiveC++ linking both languages.
