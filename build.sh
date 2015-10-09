#!/bin/sh

exitIfError() {
  if [[ $? != 0 ]]; then
    echo $1
    exit 1
  fi
}

token=`cat .slack-token`
if [[ -z "$token" ]]; then
  echo "SLACK_TOKEN needs to be stored in .slack-token file"
  exit 1
fi

channel=$1
platform=$2
commit=$3
platform_args=(${@:4})
root_path=`pwd`

if [ -z "$platform" ] || [ -z "$channel" ] || ! [[ "$platform" =~ ^(ios|android)$ ]] || [[ -z "$commit" ]]; then
  echo "Expected: <slack channel> <platform=ios|android> <commit/branch/tag> <platform args>"
  echo "Received: $@"
  exit 1
fi

# TODO: Read platform->repo mapping from a file
repo_name="tinyowl-$platform"
repo_url="git@github.com:Flutterbee/$repo_name.git"

workspace_path="$root_path/workspace"
repo_path="$workspace_path/repo/$repo_name"

# Clone repository
if [[ ! -d "$repo_path" ]]; then
  git clone $repo_url $repo_path
  exitIfError "Repository cloning failed"
fi

# Copy repo to sandbox
build_id=`uuidgen`
build_sandbox_path="$workspace_path/sandbox/$build_id"
mkdir -p $build_sandbox_path
cp -r $repo_path $build_sandbox_path
sandbox_repo_path="$build_sandbox_path/$repo_name"

cd $sandbox_repo_path

# Checkout the particular commit
# Fetch if commit isn't found
if [[ `git cat-file -t $commit` != "commit" ]]; then
  git fetch
fi
git checkout $commit
exitIfError "Could not checkout $commit"

# Check platform parameters
check_script="$sandbox_repo_path/scripts/configure-checkargs.sh"
if [[ ! -f "$check_script" ]]; then
  echo "Build scripts haven't been setup in the repository"
  exit 1
fi

sh "$check_script" $platform_args
exitIfError "Platform args don't match"

# Configure Repo
# TODO: Checkout particular tag/version
"./scripts/configure.sh" $platform_args
exitIfError "Configuration failed"
cd $root_path

# Queue background task for building, uploading, cleanup
build_cmd="cd $sandbox_repo_path && sh $root_path/build-upload.sh $token $channel $build_id && cd $root_path"

# Disown background approach
# build_cmd="($build_cmd) < /dev/null &> /dev/null & disown"

# Tmux background approach
session="slackbuild"
tmux new-window -t $session
tmux rename-window -t $session $build_id
build_cmd="tmux send-keys -t $session \"$build_cmd\" ENTER"
# TODO: cleanup_cmd="rm -rf $build_sandbox_path"
eval "$build_cmd"

echo "Build id: $build_id"
exit 0
