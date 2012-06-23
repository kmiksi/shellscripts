#!/bin/bash
# author: Carlos Eduardo Alves
# since: 2012-06-20
# version: 1.0
# license: LGPL v2+
# 
# tested in: ubuntu-11.04-amd64, ubuntu-12.04-i386

if test "`id -un`" != "root"
then
    echo "You are not root, trying with sudo" >&2
    sudo bash "$0" "$@"
    exit $?
fi

#find file location
dir=`dirname "$0"`
cd "$dir"
dir="$PWD"
cd "$OLDPWD"

#version to name components
version="3.6"
#tarball to install
tarball="$dir/firefox-3.6.28.tar.bz2"
#url to download tarball
url="http://download.mozilla.org/?product=firefox-3.6.28&os=linux&lang=pt-BR"

#provide multiple instances by default?
multiple_instances=true
#first path (to override firefox executable in $PATH)
bin="/usr/local/sbin"

#firefox & legacy versions
firefox="`which firefox`"
legacy="$firefox-$version"


#check for ld-linux or install ia32-libs
if ! test -e "/lib/ld-linux.so.2"
then
    echo "It seems that you are running on amd64, trying to install ia32-libs" >&2
    software-properties-gtk -e universe
    apt-get update
    apt-get install ia32-libs
    if test "$?" != "0"
    then
        echo "Error when installing ia32-libs" >&2
        exit 1
    fi
fi


#download tarball if needed
if ! test -e "$tarball"
then
    echo "Tarball not found, downloading"
    wget -c "$url" -O "$tarball.part"
    if test "$?" = "0"
    then
        mv "$tarball.part" "$tarball"
        chmod 777 "$tarball"
    else
        echo "ERROR while downloading tarball" >&2
        exit 1
    fi
fi

#unpack tarball
tar -jxf "$tarball" -C "/opt" #bzip2
#tar -zxf "$tarball" -C "/opt" #gzip
if test "$?" != "0"
then
    echo "Error while unpacking" >&2
    exit 1
fi
mv "/opt/firefox" "/opt/firefox-$version"
chmod +x "/opt/firefox-$version/firefox"

#create executable
echo '#!/bin/bash
profile="$HOME/.mozilla/firefox/'"$version"'-default/"
test -e "$profile" || mkdir -p "$profile"
"/opt/firefox-'"$version"'/firefox" --profile "$profile" "$@"
' > "$legacy"
chmod +x "$legacy"

#create launcher
launcher="/usr/share/applications/firefox"
cat "$launcher.desktop" |
    while read line
    do
        if test "$line" != "${line#Exec}"
        then
            echo "${line/firefox/firefox-$version}"
        elif test "$line" != "${line#Name}" \
               -a "$line" != "${line//Firefox}"
        then
            echo "$line ($version)"
        else
            echo "$line"
        fi
    done > "$launcher-$version.desktop"
chmod +x "$launcher-$version.desktop"

#override executables to provide multiple instances
if $multiple_instances
then
    echo $'#!/bin/bash\n'"$firefox"' --no-remote "$@"' > "$bin/firefox"
    chmod +x "$bin/firefox"
    echo $'#!/bin/bash\n'"$firefox-$version"' --no-remote "$@"' > "$bin/firefox-$version"
    chmod +x "$bin/firefox-$version"
fi




echo
echo "Process finished, seems that all will work."
echo "Good lucky!"



