#!/bin/bash
# 
# Install an legacy version of Firefox Web Browser on your system.
# This practice can be useful for webpage testing.
# This script will not override the system installed firefox.
# 
# author: Carlos Eduardo Alves
# since: 2012-06-20
# version: 1.1
# license: LGPL v2+
# 
# tested in: ubuntu-11.04-amd64, ubuntu-12.04-i386, ubuntu-12.04-amd64
# dependencies: firefox

################################################################################
##  CONFIGURATIONS                                                            ##
################################################################################
#version to name components
#see (http://www.mozilla.org/en-US/firefox/all-older.html)
version="3.6"
build="3.6.28"
lang="en-US" #or other like pt-BR, es-ES, de... see site

tarball="firefox-$build.tar.bz2"
url="http://download.mozilla.org/?product=firefox-$build&os=linux&lang=$lang"

#provide multiple instances as system default?
multiple_instances=true
bin="/usr/local/sbin" #to override firefox executable in $PATH

################################################################################
##  END CONFIGURATIONS                                                        ##
################################################################################

if test "`id -un`" != "root"
then
    echo "You are not root, trying with sudo" >&2
    sudo bash "$0" "$@"
    exit $?
fi

#check for ld-linux or install ia32-libs
ldlinux="/lib/ld-linux.so.2"
if ! test -e "$ldlinux"
then
    echo "It seems that you are running on amd64, trying to install ia32-libs" >&2
    software-properties-gtk -e universe
    apt-get update
    apt-get install ia32-libs
    if test "$?" != "0" -o ! -e "$ldlinux"
    then
        echo "Error when installing ia32-libs" >&2
        echo "Please provide '$ldlinux' to run firefox legacy" >&2
        exit 1
    fi
fi


#find current script location
dir=`dirname "$0"`
cd "$dir"
dir="$PWD"
cd "$OLDPWD"

#firefox & legacy versions
firefox="`which firefox`"
# get the really last executable... (because of multiple_instances feature)
for folder in ${PATH//':'/ }
do
    if test -x "$folder/firefox"
    then
        firefox="$folder/firefox"
    fi
done
legacy="$firefox-$version"

#download tarball if needed
tarball="$dir/$tarball"
if ! test -e "$tarball"
then
    echo "Tarball not found, downloading"
    wget -c "$url" -O "$tarball.part"
    if test "$?" = "0" -a -s "$tarball.part"
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
if test "$?" != "0" -o ! -d "/opt/firefox"
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

#create launcher based on system installed Firefox launcher
launcher="/usr/share/applications/firefox"
cat "$launcher.desktop" |
    while read line
    do
        if test "$line" != "${line#Exec}" #start with "Exec"
        then
            echo "${line/firefox/firefox-$version}"
        elif test "$line" != "${line#Name}" \
               -a "$line" != "${line//Firefox}" #contain this word
        then
            echo "$line ($version)" #add version mark to the name
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



