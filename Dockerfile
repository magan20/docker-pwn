FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && \
    apt-get upgrade -y && \
    apt-get install net-tools openssh-server vim ruby zsh fonts-powerline language-pack-en gdb tmux file gdbserver dh-autoreconf curl gcc ruby-dev -y && \
	apt-get install python3 python3-pip python3-dev git libssl-dev libffi-dev build-essential gdb-multiarch tree -y && \
	gem install seccomp-tools && \
	pip3 install ropgadget && \
	update-locale

# x86
RUN dpkg --add-architecture i386 && \
	apt-get update && \
	apt-get install libc6:i386 libncurses5:i386 libstdc++6:i386 -y

WORKDIR /root
RUN mkdir /root/tools

#install vim
COPY vimrc /root/.vimrc

#install tmux
WORKDIR /root
RUN git clone https://github.com/gpakosz/.tmux.git
RUN ln -s -f .tmux/.tmux.conf
RUN cp .tmux/.tmux.conf.local .

#install oh my zsh
WORKDIR /root/tools
RUN sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)" && \
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
	git clone https://github.com/zsh-users/zsh-autosuggestions  /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions && \
	sed -i 's/plugins=(git)/plugins=(git zsh-syntax-highlighting zsh-autosuggestions)/' /root/.zshrc
RUN chsh -s /usr/bin/zsh | echo 'root'

#install pwntools
WORKDIR /root
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade pwntools

#install one_gadget
WORKDIR /root/tools
RUN git clone https://github.com/david942j/one_gadget.git
WORKDIR one_gadget
RUN gem install one_gadget

#install checksec
WORKDIR /root/tools
RUN git clone https://github.com/slimm609/checksec.sh.git
RUN cp checksec.sh/checksec.bash /usr/local/bin/checksec

#install patchelf
WORKDIR /root/tools
RUN git clone https://github.com/NixOS/patchelf.git
WORKDIR patchelf
RUN ./bootstrap.sh && \
	./configure && \
	make && \
	make check && \
	make install

#set gdb
COPY gdbinit /root/.gdbinit
RUN mkdir /root/tools/gdb

#install gef
WORKDIR /root/tools/gdb
RUN git clone https://github.com/hugsy/gef.git
RUN echo "source /root/tools/gdb/gef/gef.py" > /root/.gdbinit_gef

RUN echo "export LC_ALL=en_US.UTF-8" >> /root/.zshrc
RUN echo "export PYTHONIOENCODING=UTF-8" >> /root/.zshrc

WORKDIR /root

#setting ssh
EXPOSE 22
RUN mkdir -p /run/sshd && chmod 755 /run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
CMD /usr/sbin/sshd -D
