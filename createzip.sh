# Your theme directory name (/app/themes/yourtheme)
themeName="themename"
########################################

####################
# Usage
####################
# bash wpedeploy.sh nameOfRemote
####################
# Set variables
####################
# WP Engine remote to deploy to
wpengineRemoteName=$1
# Get present working directory
presentWorkingDirectory=`pwd`
# Get current branch user is on
currentLocalGitBranch=`git rev-parse --abbrev-ref HEAD`
# Temporary git branch for building and deploying
tempDeployGitBranch="wpedeployscript/${currentLocalGitBranch}"
# KWB themes directory
ThemesDirectory="${presentWorkingDirectory}/app/themes/"

####################
# Perform checks before running script
####################

# Git checks
####################
# Halt if there are uncommitted files
if [[ -n $(git status -s) ]]; then
  echo -e "[\033[31mERROR\e[0m] Found uncommitted files on current branch \"$currentLocalGitBranch\".\n        Review and commit changes to continue."
  git status
  exit 1
fi

# Check if specified remote exist
git ls-remote "$wpengineRemoteName" &> /dev/null
if [ "$?" -ne 0 ]; then
  echo -e "[\033[31mERROR\e[0m] Unknown git remote \"$wpengineRemoteName\"\n"
  echo "Available remotes:"
  git remote -v
  exit 1
fi

# Directory checks
####################
# Halt if theme directory does not exist
if [ ! -d "$presentWorkingDirectory"/app/themes/"$themeName" ]; then
  echo -e "[\033[31mERROR\e[0m] Theme \"$themeName\" not found.\n        Set \033[32mthemeName\e[0m variable in $0 to match your theme in $ThemesDirectory"
  echo "Available themes:"
  ls $ThemesDirectory
  exit 1
fi

####################
# Begin deploy process
####################
# Checkout new temporary branch
echo "Preparing theme on branch ${tempDeployGitBranch}..."
git checkout -b "$tempDeployGitBranch" &> /dev/null

# Run composer
pilothouse composer install

# WPE-friendly gitignore
rm .gitignore &> /dev/null
echo -e "/*\n!wp-content/" > ./.gitignore

# Copy meaningful contents of app into wp-content
mkdir wp-content && cp -rp app/plugins wp-content && cp -rp app/themes wp-content

# Go into theme directory
cd "$presentWorkingDirectory/wp-content/themes/$themeName" &> /dev/null

# Build theme assets
yarn cache clean && yarn && yarn build

# Back to the top
cd "$presentWorkingDirectory"

# Cleanup wp-content
####################
# Remove sage theme cruft
# Files
# Remove Unnecesary Files
rm "$presentWorkingDirectory"/wp-content/themes/"$themeName"/.gitignore &> /dev/null
rm "$presentWorkingDirectory"/wp-content/themes/"$themeName"/package.json &> /dev/null
rm "$presentWorkingDirectory"/wp-content/themes/"$themeName"/webpack.config.js &> /dev/null
rm "$presentWorkingDirectory"/wp-content/themes/"$themeName"/yarn.lock &> /dev/null


# Remove Unnecesary Directories
rm -rf "$presentWorkingDirectory"/wp-content/themes/"$themeName"/node_modules &> /dev/null
rm -rf "$presentWorkingDirectory"/wp-content/themes/"$themeName"/assets &> /dev/null
rm -rf "$presentWorkingDirectory"/wp-content/themes/"$themeName"/webpack &> /dev/null

cd wp-content/themes/

zip -r -X "$themeName".zip "$themeName"/

cp "$themeName".zip ~/Downloads/

cd "$presentWorkingDirectory"

git checkout .

####################
# Back to a clean slate
####################
git checkout "$currentLocalGitBranch" &> /dev/null
rm -rf wp-content/ &> /dev/null
rm -rf "$themeName".zip &> /dev/null
git branch -D "$tempDeployGitBranch" &> /dev/null
echo "Done"
