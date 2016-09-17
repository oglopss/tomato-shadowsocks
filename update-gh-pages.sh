#!/usr/bin/env bash

# if [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
  echo -e "Starting to update gh-pages\n"

  echo ======== show $HOME/ss-install =======
  ls -l $HOME/ss-install

  #copy data we're interested in to other place
  mkdir -p $HOME/coverage
  cp -R $HOME/ss-install/bin/*.tar.gz $HOME/coverage

  #go to home and setup git
  cd $HOME
  git config --global user.email "travis@travis-ci.org"
  git config --global user.name "Travis"
  
  echo ===== about to clone ctng-ss-jekyll ===============
  echo 
  x=$[ ( $RANDOM % 25 )  + 10 ]s
  echo sleeping $x
  sleep $x
  
  #using token clone gh-pages branch
  git clone --quiet --branch=gh-pages https://${GH_TOKEN}@github.com/oglopss/ctng-ss-jekyll.git  gh-pages-$SS_VER > /dev/null

  #go into diractory and copy data we're interested in to that directory
  cd gh-pages-$SS_VER
  mkdir -p download && cd download
  cp -Rf $HOME/coverage/* .

  #add, commit and push files
  git add -f .
  
  # update ss.yml as well
  echo ======== show $SS_VER =======
  echo $SS_VER

  # need to regenerate _data/ss.yml
  cd ../_data

  datetime=$(date '+%d/%m/%Y %H:%M:%S %Z');

  echo ============= print ss.yml before push changes =============
  cat ./ss.yml

push_changes()
{
  git reset --hard
  # git checkout .
  # pull latest before we try something
  git pull origin gh-pages

  echo ============= print ss.yml in push changes after pull =============
  cat ./ss.yml

if grep -qe "build: $TRAVIS_BUILD_NUMBER$" ss.yml
then
    # code if found
    # update files
    if grep -qe "  - $SS_VER$" ss.yml
    then
        echo files already inside skip
    else
        cat >> ss.yml <<EOL
  - $SS_VER
EOL
    fi
  # update datetime
  sed -ie 's@^date:\s.*@date: '"$datetime"'@g' ss.yml

else
    # code if not found
    echo create new file


    cat > ss.yml <<EOL
build: $TRAVIS_BUILD_NUMBER
date: $datetime
files:
  - $SS_VER
EOL

fi

  
  echo ============= print ss.yml =============
  cat ./ss.yml
  git add -f ss.yml
  
  git commit -m "Travis build $TRAVIS_BUILD_NUMBER $SS_VER pushed to gh-pages"
  # git push -fq origin gh-pages # > /dev/null

  # keep retrying until push successful
  git pull origin gh-pages
  # pushcmd="git push -fq origin gh-pages"
  pushcmd="git push origin gh-pages"
  eval "$pushcmd"

}


  push_changes  
  ret=$?
  # echo ========= the value "$ret" ============
  while ! test "$ret" -eq 0
  do
      echo >&2 "push failed with exit status $ret"
      x=$[ ( $RANDOM % 20 )  + 10 ]s
      echo sleeping $x
      sleep $x
      echo wake up!
      # exit 1
      # git pull origin gh-pages
      # eval "$pushcmd"
      push_changes
      ret=$?
  done

  echo -e "Done magic with love\n"
  
# fi
