dotnet publish
rmdir /s /q obj
bflat build --no-reflection --no-stacktrace-data --no-globalization --no-exception-messages -Os --no-pie --separate-symbols --os:linux --arch:arm64 --libc:bionic -r:bin\Release\net8.0\publish\Crapto1Sharp.dll
del libCrapto1Native.so.dwo

if not exist ..\android\app\src\main\jniLibs\arm64-v8a\ mkdir ..\android\app\src\main\jniLibs\arm64-v8a\

move libCrapto1Native.so ..\android\app\src\main\jniLibs\arm64-v8a\libCrapto1Native.so