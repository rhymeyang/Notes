#!/bin/bash


source activate py36R

source "./source/shell/lib"
source "./deploy.conf"

declare -r workDir=${PWD}
declare -r siteDir="${workDir}/_site"
declare -r indexfile="${siteDir}/index.md"

function __clean_site_dir(){
    cd ${siteDir}
    keepArray=( "\.git" "\.gitignore" "README.md"  '\.'  '\..')
    allFiles=$(ls -a)
    
    msg_info "will remove file under ${siteDir}"
    msg_info "origin files ${allFiles}"
    for checkFile in ${keepArray[@]}
    do
        allFiles=$(echo ${allFiles}| 
            # sed  -e "s/[^ ]${checkFile}[ $]/ /g"  |
            sed  -e "s/ ${checkFile} / /g"  |
            sed  -e "s/^${checkFile}[ |$]/ /g" |
            sed  -e "s/ ${checkFile}$/ /g")
        
    done

    allFileArray=($(echo ${allFiles}))
    
    msg_info "will remove "
    msg_warning "${allFileArray[@]}"
    

    for actualFile in ${allFileArray[@]}    
    do
        rm -rf ${actualFile}
    done
    msg_info "after remove, path ${PWD}"

    msg_info "$(ls -a)"
}


function _rm_site_dir(){
    cd ${workDir}

    if [ -d ${siteDir} ]; then
        rm -rf "${siteDir}"
    fi
    git worktree prune
}

function _add_site_dir(){
    cd ${workDir}

    if [ -d ${siteDir} ]; then
        msg_error "${siteDir} exist, should not add again"
        return
    fi

    git worktree add  ${siteDir} ${branchSite}

    cd ${siteDir}
    git pull ${remRepo} ${branchSite}
}
function _clean_site_dir(){
    cd ${siteDir}
    keepArray=( "\.git" "\.gitignore" "README.md"  '\.'  '\..')
    allFiles=$(ls -a)
    
    msg_info "will remove file under ${siteDir}"
    msg_info "origin files ${allFiles}"
    for checkFile in ${keepArray[@]}
    do
        allFiles=$(echo ${allFiles}| 
            # sed  -e "s/[^ ]${checkFile}[ $]/ /g"  |
            sed  -e "s/ ${checkFile} / /g"  |
            sed  -e "s/^${checkFile}[ |$]/ /g" |
            sed  -e "s/ ${checkFile}$/ /g")
        
    done

    allFileArray=($(echo ${allFiles}))
    
    msg_info "will remove "
    msg_warning "${allFileArray[@]}"
    

    for actualFile in ${allFileArray[@]}    
    do
        rm -rf ${actualFile}
    done
    msg_info "after remove, path ${PWD}"

    msg_info "$(ls -a)"
}
function convert_ipynb_list(){
    cd ${workDir}
    msg_header "Will convert ipynb. Wait ..."
    msg_info " current PATH $PWD"
    file_list=$(find _post/ -name *.ipynb | grep -v .ipynb_checkpoints| grep -v ^$)
    # msg_info "origin files"
    # msg_info "${file_list[@]}"
    
    echo ""> ${indexfile}
    for org_file in ${file_list[@]}
    do
        tar_file=$(echo ${org_file}| sed  -e "s/^_post/_site/g" | sed  -e "s/.ipynb$/.html/g")
        article_name=$(echo ${org_file##*/}| sed  -e "s/.ipynb//g")

        msg_info "article_name $article_name"

        ipython nbconvert --to html ${org_file} 
        org_html=$(echo ${org_file}| sed  -e "s/.ipynb$/.html/g" )
        tar_dir=${tar_file%/*}

        msg_info "tar_dir $tar_dir"

        if [ !  -d $tar_dir ]; then
            mkdir -p $tar_dir
        fi
        # msg_info $org_file
        # msg_warning $tar_file
        msg_info "mv -f $org_html $tar_file"
        
        mv -f $org_html $tar_file
        tar_file=$(echo ${tar_file}| sed -e "s/^_site//g")
        echo "+ [$article_name](${baseUrl}${tar_file})" >> ${indexfile}
        # echo ${tar_file} | sed  -e "s/^_site/[$article_name](${baseUrl})/g" >> ${indexfile}
    done
}

function _refresh_site_dir(){
    msg_header "Will refresh site Wait ..."
    _rm_site_dir
    _add_site_dir
    _clean_site_dir
}

function _deploy_site(){
  
  if [[ $isCompile=="yes" ]]; then
    cd ${workDir}
    _refresh_site_dir

    convert_ipynb_list

  fi

  cd ${siteDir}
  git add -A .
  
  if [[ ${siteSave}=='no' ]]; then
      git commit --amend -m "$commit - $(date)"
      msg_warning "will run git push -f -u ${remRepo} ${branchSite}"
      git push -f -u ${remRepo} ${branchSite}
  else
      git commit -m "$commit - $(date)"
      git push ${remRepo} -u ${branchSite}
  fi

  msg_finish "Done!"
}


# echo $file_list
# Menu
case $1 in
    build )
        _add_site_dir
        _clean_site_dir
        convert_ipynb_list
        msg_finish "Done!"
        ;;
   
    build:clean )
        _refresh_site_dir
        convert_ipynb_list
        msg_finish "Done!"
        ;;
   
    deploy:site)
        _deploy_site
        ;;
    *|help)
     msg_warning "Usage: $0 { build | build:clean | deploy:site }"
  ;;
esac