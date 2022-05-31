time /T > %appdata%\Rime\lua_log.txt
copy *.yaml %appdata%\Rime
copy lua\* %appdata%\Rime\lua
"C:\Program Files (x86)\Rime\weasel-0.14.3\WeaselDeployer.exe" /deploy
PAUSE 