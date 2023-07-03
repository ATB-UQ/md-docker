FROM ubuntu:latest

RUN apt update && DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-desktop dbus-x11 policykit-1-gnome locales

#rebooting not allowed
RUN rm /run/reboot-required*

#create user, add to sudo
RUN useradd -m testuser -p $(openssl passwd 1234)
RUN usermod -aG sudo testuser

#xrdp
RUN apt install -y xrdp 
RUN adduser xrdp ssl-cert

# Set the locale
RUN sed -i '/en_AU.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen
ENV LANG en_AU.UTF-8  
ENV LANGUAGE en_AU:en  
ENV LC_ALL en_AU.UTF-8 

RUN echo "locales locales/default_environment_locale select en_AU.UTF-8" | debconf-set-selections
RUN echo "locales locales/locales_to_be_generated multiselect en_AU.UTF-8 UTF-8" | debconf-set-selections
RUN rm "/etc/locale.gen"
RUN dpkg-reconfigure --frontend noninteractive locales

RUN sed -i '3 a echo "\
export GNOME_SHELL_SESSION_MODE=ubuntu\\n\
export XDG_SESSION_TYPE=x11\\n\
export XDG_CURRENT_DESKTOP=ubuntu:GNOME\\n\
export XDG_CONFIG_DIRS=/etc/xdg/xdg-ubuntu:/etc/xdg\\n\
" > ~/.xsessionrc' /etc/xrdp/startwm.sh

#firefox
RUN add-apt-repository ppa:mozillateam/ppa
RUN echo '\
Package: *\
Pin: release o=LP-PPA-mozillateam\
Pin-Priority: 1001\
' | tee /etc/apt/preferences.d/mozilla-firefox
RUN echo 'Unattended-Upgrade::Allowed-Origins:: "LP-PPA-mozillateam:${distro_codename}";' | tee /etc/apt/apt.conf.d/51unattended-upgrades-firefox
RUN apt install firefox

EXPOSE 3389

CMD service dbus start; /usr/lib/systemd/systemd-logind & service xrdp start ; bash