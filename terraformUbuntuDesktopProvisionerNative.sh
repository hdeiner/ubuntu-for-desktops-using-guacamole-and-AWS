#!/usr/bin/env bash

# Install Docker
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq update
sudo DEBIAN_FRONTEND=noninteractive apt-get install apt-transport-https ca-certificates curl software-properties-common -yqq
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq update
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install docker-ce
sudo usermod -aG docker ubuntu
sudo systemctl restart docker
sudo systemctl enable docker

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.26.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install tomcat8
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq update
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install tomcat8 tomcat8-admin tomcat8-common tomcat8-user ghostscript jq wget curl

# Start tomcat8
sudo systemctl start tomcat8
sudo systemctl enable tomcat8
sudo systemctl stop tomcat8

# make tomcat run on port 80
sudo sed -i 's/8080/80/g' /etc/tomcat8/server.xml
sudo touch /etc/authbind/byport/80
sudo chmod 500 /etc/authbind/byport/80
sudo chown tomcat8 /etc/authbind/byport/80
sudo sed -i 's/exec /exec authbind --deep /g' /usr/share/tomcat8/bin/startup.sh
sudo sed -i 's/#AUTHBIND=no/AUTHBIND=yes/g' /etc/default/tomcat8
sudo systemctl start tomcat8

# Install guacamole dependencies
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq update
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install gcc-6 g++-6 libcairo2-dev libjpeg-turbo8-dev libpng-dev libossp-uuid-dev
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install libavcodec-dev libavutil-dev libswscale-dev libfreerdp-dev libpango1.0-dev
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install libssh2-1-dev libtelnet-dev libvncserver-dev libssl-dev libvorbis-dev libwebp-dev

# Download and extract Guacamole Files
sudo wget https://apache.claz.org/guacamole/1.1.0/source/guacamole-server-1.1.0.tar.gz
sudo wget https://apache.claz.org/guacamole/1.1.0/binary/guacamole-1.1.0.war
sudo tar -xzf guacamole-server-1.1.0.tar.gz

# make Guacamole Directories and Install guacd
sudo mkdir /etc/guacamole
sudo mkdir /etc/guacamole/lib
sudo mkdir /etc/guacamole/extensions
cd guacamole-server-1.1.0
sudo ./configure --with-init-dir=/etc/init.d
sudo make -s
sudo make -s install
sudo ldconfig
sudo systemctl start guacd
sudo systemctl enable guacd
cd ..

# Move guacamole files to correct locations
sudo mv guacamole-1.1.0.war /etc/guacamole/guacamole.war
sudo ln -s /etc/guacamole/guacamole.war /var/lib/tomcat8/webapps/
sudo rm -rf /var/lib/tomcat8/webapps/ROOT
sudo mv /var/lib/tomcat8/webapps/guacamole.war /var/lib/tomcat8/webapps/ROOT.war
sudo rm -rf /usr/share/tomcat8/.guacamole
sudo ln -s /etc/guacamole /usr/share/tomcat8/.guacamole
sudo rm -rf guacamole-server-1.1.0.tar.gz

# Install vncserver and desktop for ubuntu
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq update
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install tightvncserver xfce4 xfce4-goodies  gnome-icon-theme tango-icon-theme
sudo DEBIAN_FRONTEND=noninteractive apt-get -yqq install vim gedit firefox mate-desktop-environment

# Make a VNC password file
mkdir .vnc
echo "VNCPASS" | vncpasswd -f > .vnc/passwd
sudo chmod 0600 .vnc/passwd

sudo bash -c 'cat<< EOF >> /etc/guacamole/user-mapping.xml
<user-mapping>
    <authorize username="USERNAME" password="PASSWORD">
        <connection name="Ubuntu for Desktops Using Guacamole and AWS">
            <protocol>vnc</protocol>
            <param name="hostname">localhost</param>
            <param name="port">5901</param>
            <param name="password">VNCPASS</param>
        </connection>
    </authorize>
</user-mapping>
EOF'

# Restart tomcat8 and guacd for guacamole changes to take effect
sudo systemctl restart tomcat8
sudo systemctl restart guacd

# Configure VNCSERVER to bring up desktop
bash -c "cat << EOF >> .vnc/xstartup
#!/bin/sh
#xrdb $HOME/.Xresources
# Fix to make GNOME work
export XKL_XMODMAP_DISABLE=1
#startxfce4 &
mate-session &
DISPLAY=:1 xfce4-terminal --default-working-directory=/home/ubuntu/Desktop
EOF"
chmod +x .vnc/xstartup

# xfce4-terminal settings
mkdir -p .config/xfce4/terminal
bash -c "cat << EOF >> .config/xfce4/terminal/terminalrc
[Configuration]
FontName=Monospace 16
MiscAlwaysShowTabs=FALSE
MiscBell=FALSE
MiscBorderDefault=TRUE
MiscCursorBlinks=FALSE
MiscCursorShape=TERMINAL_CURSOR_SHAPE_BLOCK
MiscDefaultGeometry=100x24
MiscInheritGeometry=FALSE
MiscMenubarDefault=TRUE
MiscMouseAutohide=FALSE
MiscToolbarDefault=FALSE
MiscConfirmClose=TRUE
MiscCycleTabs=TRUE
MiscTabCloseButtons=TRUE
MiscTabCloseMiddleClick=TRUE
MiscTabPosition=GTK_POS_TOP
MiscHighlightUrls=TRUE
MiscScrollAlternateScreen=TRUE
EOF"

# Configure tightvncserver to start on reboot
sudo bash -c "cat << EOF >> /etc/systemd/system/vncserver@1.service
[Unit]
Description=Start a VNC Session at startup With Desktop ID 1
After=multi-user.target network.target

[Service]
Type=forking
User=ubuntu
ExecStartPre=/bin/sh -c '/usr/bin/tightvncserver -kill :%i > /dev/null 2>&1 || :'
ExecStart=/usr/bin/tightvncserver :1 -geometry 1280x768 -depth 24
ExecStop=/usr/bin/tightvncserver -kill :%i

[Install]
WantedBy=multi-user.target
EOF"
sudo systemctl daemon-reload
sudo systemctl enable vncserver@1.service

# Install Java development environment
sudo DEBIAN_FRONTEND=noninteractive apt -yqq update
sudo DEBIAN_FRONTEND=noninteractive apt -yqq install openjdk-8-jdk-headless maven

# Seed the sample files
mkdir -p /home/ubuntu/Desktop
cd /home/ubuntu/Desktop
curl https://raw.githubusercontent.com/hdeiner/ubuntu-for-desktops-using-guacamole-and-AWS/master/assets/_sample-DockerFile -o /home/ubuntu/Desktop/Dockerfile
curl https://raw.githubusercontent.com/hdeiner/ubuntu-for-desktops-using-guacamole-and-AWS/master/assets/_sample-DockerFileCmdEntrypoint -o /home/ubuntu/Desktop/DockerfileCmdEntrypoint
curl https://raw.githubusercontent.com/hdeiner/ubuntu-for-desktops-using-guacamole-and-AWS/master/assets/_sample-DockerFileCurl -o /home/ubuntu/Desktop/DockerfileCurl
curl https://raw.githubusercontent.com/hdeiner/ubuntu-for-desktops-using-guacamole-and-AWS/master/assets/_sample-sample.war -o /home/ubuntu/Desktop/sample.war
curl https://raw.githubusercontent.com/hdeiner/ubuntu-for-desktops-using-guacamole-and-AWS/master/assets/_sample_docker-compose.yml -o /home/ubuntu/Desktop/docker-compose.yml
curl https://raw.githubusercontent.com/hdeiner/ubuntu-for-desktops-using-guacamole-and-AWS/master/assets/_sample_wiremock.tar -o /home/ubuntu/Desktop/wiremock.tar
tar -xvf wiremock.tar
rm wiremock.tar
curl https://raw.githubusercontent.com/hdeiner/ubuntu-for-desktops-using-guacamole-and-AWS/master/assets/zipster.tar -o /home/ubuntu/Desktop/zipster.tar
tar -xvf zipster.tar
rm zipster.tar