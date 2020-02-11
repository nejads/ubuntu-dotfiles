export EDITOR='code'

####################
# Path
####################
export PATH="/bin:$PATH"
export PATH="/sbin:$PATH"
export PATH="/usr/bin:$PATH"
export PATH="/usr/sbin:$PATH"

# brew symlinks most executables it installs
export PATH="/usr/local/bin:$PATH"

# brew symlinks some of its executables
export PATH="/usr/local/sbin:$PATH"

# the symlinked brew Ruby executable
export PATH="/usr/local/opt/ruby/bin:$PATH"

# java 
export JAVA_HOME="/usr/lib/jvm/java-1.8.0-amazon-corretto"
