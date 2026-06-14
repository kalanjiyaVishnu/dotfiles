if status is-interactive
    # Commands to run in interactive sessions can go here
end
alias zshconfig="vim ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
#system
alias update="sudo apt-get update"
alias install="sudo apt-get install"

export ZSH="$HOME/.oh-my-zsh"
# export ES_HOME="$HOME/Documents/elasticsearch-5.4.3/bin/elasticsearch"
export ES_HOME="$HOME/Documents/elasticsearch-5.4.3/bin/elasticsearch"
export KB_HOME="/opt/kibana/bin"

set -gx KAFKA_HOME /opt/kafka
set -gx PATH $KAFKA_HOME/bin $PATH
set -x SPARK_HOME /opt/spark
set -x KIBANA_HOME /opt/kibana
set -x PATH $SPARK_HOME/bin $SPARK_HOME/sbin $PATH
export HADOOP_HOME=$HOME/bin/hadoop-2.7.7
export HADOOP_COMMON_LIB_NATIVE_DIR=$HADOOP_HOME/lib/native
export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
export _CONDA_ROOT="/home/vishnu/anaconda3"
export JAVA_HOME="/home/vishnu/.sdkman/candidates/java/current"
export JAVA_HOME_D="/home/vishnu/.sdkman/candidates/java/current"
export KOTLIN_HOME_="/usr/bin/kotlin"
set -x NVM_DIR "$HOME/.nvm"
#git
alias gs="git status"
alias gco="git checkout"
alias log="git log"
alias clone="git clone"
alias stash="git stash"
alias spop="git stash pop"
alias commit="git commit -m"
alias add="git add"
alias push="git push"
alias pull="git pull"
alias docker="sudo docker"
alias branch="git branch"

#casa projects
alias casa="cd ~/casa"
alias zookeper="cd $KAFKA_HOME && ./bin/zookeeper-server-start.sh config/zookeeper.properties"
alias kafka="cd $KAFKA_HOME && ./bin/kafka-server-start.sh config/server.properties"
alias kgn="$KAFKA_HOME/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic "groupone_requests_01" --from-beginning"
alias lightning-blade="cd ~/CasaProjects && ./runCasa.sh"
alias chidori="cd ~/CasaProjects && ./sabRunCasa.sh"
alias keycloak="cd ~/keycloak/keycloak-13.0.1/bin && ./standalone.sh"
alias keycloak-dev="sdk use java 17.0.8.1-tem && ./Downloads/keycloak-22.0.1/bin/kc.sh start-dev"
alias mongo="sudo systemctl start mongodb"
alias mongos="sudo systemctl stop mongodb"
alias mongoui="cd ~/NoSql && ./nosqlbooster4mongo-6.2.15.AppImage"
alias ismongo="service mongod status"
#alias code="code-insiders"
# alias es="cd ~/bin/elasticsearch-5.4.3/bin && ./elasticsearch"
alias kafkaui="cd ~/bin/KafkaMagic && ./kafkaMagic"
alias kibana="cd $KB_HOME && ./kibana"
alias kib="/home/vishnu/user_scripts/kib.sh"
alias es="/home/vishnu/user_scripts/es.sh"
alias rule-server="cd ~/casa/casa-rule-server"
alias rule-ui="cd ~/casa/casa-rule-ui"
alias web-app="cd ~/casa/casa-web-app"
alias dashbord="cd ~/casa/casa-dashboard"
alias dashbord-start="cd ~/casa/casa-dashboard && npm start"
alias web-app-start="cd ~/casa/casa-web-app && npm start"
alias rule-server-start="cd ~/casa/casa-rule-server && nvm use && npm run start"
alias api-server-start="cd ~/casa/api-server && nvm use && npm dev-start"
alias iot_web="cd ~/casa/iot-web-api && ./gradlew bootRun"
alias csdl="cd ~/casa/casa-scheduler && ./gradlew bootRun"
alias rs="npm run server:dev:watch"
alias rwa="npm start run"
alias ns="npm run start"
alias rticle="cd ~/personalProjects/rticle"
alias zookeeper_start="$KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties"
alias kafka_start="$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties"
# ssh
# others
alias datagrip="cd ~/bin/DataGrip-2021.3.3/bin && ./datagrip.sh"
alias alias-show="cat ~/.zshrc"
alias zoro="cd /home/debl/zoro"
# run repos
alias kibprod="cd $KB_HOME && git checkout prod && cat ../config/kibana.yml | grep 9 && kibana"
alias kibmaster="cd $KB_HOME && git checkout master && cat ../config/kibana.yml | grep 9 && kibana"
alias kibqa="cd $KB_HOME && git checkout qa && cat ../config/kibana.yml | grep 9 && kibana"
alias kibpreprod="cd $KB_HOME && git checkout preprod && cat ../config/kibana.yml | grep 9 && kibana"

# Another
alias terminator_dev="ternminator --layout="dev""
alias zsh_e="gedit ~/.zshrc"
alias zshconfig="cat ~/.zshrc"
alias ll="ls -alF"
alias la="ls -A"
alias down="cd ~/Downloads"
alias fish_e="code ~/.config/fish/config.fish"

# Another
alias casa_qa="ssh -i ~/.ssh/casa-qa ubuntu@api.casaqa.ajira.tech"
alias casa_prod="ssh -i ~/.ssh/casa-production ubuntu@deploy.casa.ajira.tech"
alias casa_project_vm="ssh -i "~/.ssh/Casa-Retail-QA-Server-KP.pem" ubuntu@13.127.0"
alias es_prod="ssh -i ~/.ssh/casa-production -nNt -L 9404:localhost:9200 ubuntu@deploy.casa.ajira.tech"
alias es_qa="ssh -i ~/.ssh/casa-qa -nNt -L 9403:localhost:9200 ubuntu@api.casaqa.ajira.tech"
# alias ch_prod="clickhouse-client --host casa-clickhouse.cloud.ajira.tech --password <REDACTED-SEE-PASSWORD-MANAGER> --port 9000"
# alias ch_qa="clickhouse-client --host api.casaqa.ajira.tech --user default --password <REDACTED-SEE-PASSWORD-MANAGER> --port 9000"
alias ch_prod_tcp="ssh -i ~/.ssh/casa-production -nNt -L 9000:20.193.141.185:9000 ubuntu@deploy.casa.ajira.tech"
alias ch_qa_tcp="ssh -i ~/.ssh/casa-qa -nNT -L 9000:10.9.0.7:9000 ubuntu@4.240.53.19"
alias ch_prod='ssh -i ~/.ssh/casa-production -nNt -L 8443:10.12.0.4:8123 ubuntu@deploy.casa.ajira.tech'
alias tunnel_ch_qa="ssh -i ~/.ssh/casa-qa -nNT -L 8443:10.9.0.7:8443 ubuntu@api.casaqa.ajira.tech"
alias es_preprod="ssh -i ~/.ssh/casa-preprod -nNT  -L 9402:localhost:9200 ubuntu@deploy.qa.casaretail.ai"
alias preprod="ssh -i ~/.ssh/casa-preprod ubuntu@deploy.qa.casaretail.ai"
alias prod= "ssh -i ~/.ssh/casa-production ubuntu@deploy.casa.ajira.tech"
alias qa="ssh -i ~/.ssh/casa-qa ubuntu@20.198.124.226"
alias python='python3'
alias postgres_qa="ssh -i ~/.ssh/casa-qa -nNT  -L 5124:localhost:5432 ubuntu@api.casaqa.ajira.tech"

alias postgres_preprod="ssh -i ~/.ssh/casa-preprod -nNT  -L 5124:localhost:5432 ubuntu@deploy.qa.casaretail.ai"
alias postgres_prod='ssh -i ~/.ssh/casa-production -nNT  -L 5124:postgres.casaretail.ai:5432 ubuntu@deploy.casa.ajira.tech'
alias xtendr="ssh -i ~/.ssh/xtendr-creator-qa.pem ubuntu@ec2-13-233-118-246.ap-south-1.compute.amazonaws.com"
alias key_cloack_qa="ssh -i ~/.ssh/casa-qa -nNT  -L 8080:localhost:8080 ubuntu@4.240.53.19"
# personal
alias projects="cd /home/vishnu/Documents/vishnu/p"
alias rw="npm run watch"
alias dev="npm run dev"
alias cd="z"
alias n="nvim"
# node
# function nvm
#    bass source $HOME/.nvm/nvm.sh --no-use ';' nvm $argv
# end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
if test -f /home/vishnu/anaconda3/bin/conda
    eval /home/vishnu/anaconda3/bin/conda "shell.fish" hook $argv | source
else
    if test -f "/home/vishnu/anaconda3/etc/fish/conf.d/conda.fish"
        . "/home/vishnu/anaconda3/etc/fish/conf.d/conda.fish"
    else
        set -x PATH /home/vishnu/anaconda3/bin $PATH
    end
end
# <<< conda initialize <<<
export PATH="$PATH:/home/vishnu/.local/share/coursier/bin"

# function _nvmrc_hook
#     echo $PWD
#     if test $PWD = $PREV_PWD
#         return
#     end
# 
#     set -g PREV_PWD $PWD
#     test -f .nvmrc; and nvm use
# end

# if not contains _nvmrc_hook "$PROMPT_COMMAND"
#    set -g PROMPT_COMMAND "_nvmrc_hook; $PROMPT_COMMAND"
#end

set --export SDKMAN_DIR "$HOME/.sdkman"
# set --export GEM_HOME (ruby -e 'puts Gem.user_dir')
set --export PATH $PATH $GEM_HOME/bin

export XDG_CONFIG_HOME="$HOME/.config"
zoxide init fish | source
alias kafka-consumer="$HOME/user_scripts/kafka-console-consumer.sh"

#pyenv init - | source

set -Ux PYENV_ROOT $HOME/.pyenv
fish_add_path $PYENV_ROOT/bin

export DOTNET_ROOT=$HOME/.dotnet
# source "$HOME/.cargo/env.fish"
set -x PATH $KIBANA_HOME/bin $PATH
set -x PATH $SPARK_HOME/bin $SPARK_HOME/sbin $PATH
export PATH="$HOME/.local/bin:$PATH"
