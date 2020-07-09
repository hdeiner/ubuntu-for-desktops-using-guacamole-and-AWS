FROM ubuntu:16.04

# UBUNTU 16.04 WITH GUACAMOLE 1.1.0, TOMCAT8, TIGHTVNC, Docker, and docker-compose

# Add Docker apt-repository repository
RUN DEBIAN_FRONTEND=noninteractive apt-get -yqq update \
 && DEBIAN_FRONTEND=noninteractive apt-get -yqq install apt-transport-https ca-certificates curl gnupg-agent software-properties-common \
 && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add - \
 && add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install docker-compose
RUN curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
 && chmod +x /usr/local/bin/docker-compose

# Install the stuff that we depend on later
RUN DEBIAN_FRONTEND=noninteractive apt-get -yqq update \
 && DEBIAN_FRONTEND=noninteractive apt-get -yqq install build-essential libcairo2-dev libjpeg-turbo8-dev libpng12-dev libossp-uuid-dev \
 && DEBIAN_FRONTEND=noninteractive apt-get -yqq install libavcodec-dev libavutil-dev libswscale-dev libfreerdp-dev libpango1.0-dev \
 && DEBIAN_FRONTEND=noninteractive apt-get -yqq install libssh2-1-dev libtelnet-dev libvncserver-dev libpulse-dev libssl-dev \
 && DEBIAN_FRONTEND=noninteractive apt-get -yqq install libvorbis-dev libwebp-dev tomcat8 freerdp ghostscript jq wget curl \
 && DEBIAN_FRONTEND=noninteractive apt-get -yqq install tightvncserver xfce4 xfce4-goodies  gnome-icon-theme-full tango-icon-theme \
 && DEBIAN_FRONTEND=noninteractive apt-get -yqq install vim gedit firefox mate-desktop-environment docker-ce docker-ce-cli containerd.io

# Download and extract Guacamole Files
RUN wget https://apache.claz.org/guacamole/1.1.0/source/guacamole-server-1.1.0.tar.gz \
 && wget https://apache.claz.org/guacamole/1.1.0/binary/guacamole-1.1.0.war \
 && tar -xzf guacamole-server-1.1.0.tar.gz

# make Guacamole Directories and Install guacd
RUN mkdir /etc/guacamole \
 && mkdir /etc/guacamole/lib \
 && mkdir /etc/guacamole/extensions \
 && cd guacamole-server-1.1.0 \
 && ./configure --with-init-dir=/etc/init.d \
 && make \
 && make install \
 && ldconfig \
 && systemctl enable guacd \
 && cd ..

 # Move guacamole files to correct locations
 RUN mv guacamole-1.1.0.war /etc/guacamole/guacamole.war \
  && ln -s /etc/guacamole/guacamole.war /var/lib/tomcat8/webapps/ \
  && rm -rf /var/lib/tomcat8/webapps/ROOT \
  && mv /var/lib/tomcat8/webapps/guacamole.war /var/lib/tomcat8/webapps/ROOT.war \
  && ln -s /usr/local/lib/freerdp/* /usr/lib/x86_64-linux-gnu/freerdp/. \
  && rm -rf /usr/share/tomcat8/.guacamole \
  && ln -s /etc/guacamole /usr/share/tomcat8/.guacamole \
  && rm -rf guacamole-server-1.1.0.tar.gz

# Make a VNC password file
RUN mkdir /root/.vnc \
 && echo "VNCPASS" | vncpasswd -f > /root/.vnc/passwd \
 && chmod 0600 /root/.vnc/passwd

# Add GUACAMOLE_HOME to Tomcat8 ENV
RUN chmod +w /etc/default/tomcat8 \
 && echo "" >> /etc/default/tomcat8 \
 && echo "# GUACAMOLE EVN VARIABLE" >> /etc/default/tomcat8 \
 && echo "GUACAMOLE_HOME=/etc/guacamole" >> /etc/default/tomcat8

# configure guacamole server
RUN echo "\
guacd-hostname:     localhost\n\
guacd-port:         4822\n\
user-mapping:       /etc/guacamole/user-mapping.xml\n\
auth-provider:      net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider\n\
basic-user-mapping: /etc/guacamole/user-mapping.xml\
" >> /etc/guacamole/guacamole.properties

RUN echo "\
<user-mapping>\n\
    <authorize username=\"USERNAME\" password=\"PASSWORD\">\n\
        <connection name=\"Agile Engineering Workshop\">\n\
            <protocol>vnc</protocol>\n\
            <param name=\"hostname\">localhost</param>\n\
            <param name=\"port\">5901</param>\n\
            <param name=\"password\">VNCPASS</param>\n\
        </connection>\n\
    </authorize>\n\
</user-mapping>\
" >> /etc/guacamole/user-mapping.xml

# Configure VNCSERVER to bring up desktop
RUN echo "\
#!/bin/sh\n\
#xrdb $HOME/.Xresources\n\
# Fix to make GNOME work\n\
export XKL_XMODMAP_DISABLE=1\n\
#startxfce4 &\n\
mate-session &\n\
DISPLAY=:1 xfce4-terminal --default-working-directory=/root/Desktop \
" >> /home/ubuntu/.vnc/xstartup \
 && chmod +x /home/ubuntu/.vnc/xstartup

# xfce4-terminal settings
RUN mkdir -p /root/.config/xfce4/terminal \
 && echo "\
[Configuration]\n\
FontName=Monospace 16\n\
MiscAlwaysShowTabs=FALSE\n\
MiscBell=FALSE\n\
MiscBorderDefault=TRUE\n\
MiscCursorBlinks=FALSE\n\
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK\n\
MiscDefaultGeometry=100x24\n\
MiscInheritGeometry=FALSE\n\
MiscMenubarDefault=TRUE\n\
MiscMouseAutohide=FALSE\n\
MiscToolbarDefault=FALSE\n\
MiscConfirmClose=TRUE\n\
MiscCycleTabs=TRUE\n\
MiscTabCloseButtons=TRUE\n\
MiscTabCloseMiddleClick=TRUE\n\
MiscTabPosition=GTK_POS_TOP\n\
MiscHighlightUrls=TRUE\n\
MiscScrollAlternateScreen=TRUE\
" >> /root/.config/xfce4/terminal/terminalrc

# Configure vncserver to start on reboot
RUN echo "\
#!/bin/sh\n\
# /etc/init.d/tightvncserver\n\
  case \"\$1\" in\n\
  start)\n\
    -u root /usr/bin/tightvncserver :1 -geometry 1280x768 -depth 24\n\
    echo 'Starting TightVNC server'\n\
    ;;\n\
  stop)\n\
    pkill Xtightvnc\n\
    echo 'Tightvncserver stopped'\n\
    ;;\n\
  *)\n\
    echo 'Usage: /etc/init.d/tightvncserver {start|stop}'\n\
    exit 1\n\
    ;;\n\
esac\n\
exit 0\
" >> /etc/init.d/tightvncserver

RUN chmod 755 /etc/init.d/tightvncserver \
 && update-rc.d tightvncserver defaults

# Put sample files into Desktop
ADD assets/_sample-DockerFile /root/Desktop/Dockerfile
ADD assets/_sample-sample.war /root/Desktop/sample.war
ADD assets/_sample-DockerFileCmdEntrypoint /root/Desktop/DockerfileCmdEntrypoint
ADD assets/_sample-DockerFileCurl /root/Desktop/DockerfileCurl
ADD assets/_sample_docker-compose.yml /root/Desktop/docker-compose.yml
ADD assets/_sample_wiremock.tar /root/Desktop/

# make sure that tomcat uses ports that won't interfere with other tomcat servers
RUN sed -i 's/80/90/g' /etc/tomcat8/server.xml

#CMD service tomcat8 start ; service docker start ; guacd ; USER=root && export USER &&  tightvncserver :1 -geometry 1280x768 -depth 24 && sleep 999d

ENTRYPOINT [ "/bin/bash", "-c", "service tomcat8 start ; service docker start ; guacd ; USER=ubuntu && export USER && tightvncserver :1 -geometry 1280x768 -depth 24 && tail -f /dev/null" ]