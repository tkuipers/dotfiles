from ubuntu:18.04

run apt-get update
run apt-get install -y wget vim openssh-server openjdk-8-jdk git git-svn clang build-essential 
run wget https://raw.githubusercontent.com/tkuipers/dotfiles/master/.bashrc
run mv .bashrc /root/.bashrc


#docker run -it -v '/c/:/c' local/machine:latest
