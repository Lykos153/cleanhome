#!/usr/bin/env nu

def isdir [path: string = "."] {
  ($path | path type) == "dir"
}

def isgitrepo [path: string = "."] {
  (isdir $path) and (($path + "/.git") | path exists)
}

def iscleangitrepo [path: string = "."] {
  (isgitrepo $path) and (git -C $path status -s) == ""
}

def containsgitrepo [path: string = "."] {
  ls $path | any {|in| isgitrepo $in.name}
}

export def containsonlygitrepos [path: string = "."] {
  ls $path | reduce --fold false {|it,acc|
    if (all {|it| isgitrepo $it.name}) {
      true
    } else {
      false
      
    }
  }
}

def cleanstate [path: string = "."] {
    if not (isdir $path) {
      "file"
    } else if (iscleangitrepo $path) {
      "clean"
    } else if (isgitrepo $path) {
      "dirty"
    # } else if (containsonlygitrepos $path) {
    #   "onlyrepos"
    # } else if (containsgitrepo $path) {
    #   "mixed"
    } else {
      "dir"
    }
}

def filterclean [] {
  if ($in != null and (($in | length) > 0) and ($in | all {|it| not (isgitrepo $it.name) })) {{name: (dirname $in.0.name), state: "dir"}} else {$in}
}

export def findunmanaged [path: string = "."] {
  ls $path | reduce --fold [] {|it, acc|
    let $state = cleanstate $it.name
    $acc | append (match $state {
      "clean" => null
      "dir" => (findunmanaged $it.name | filterclean)
      _ => {
        name: $it.name
        state: $state
      }
    })
  }
}

def main [path: string = "."] {
  findunmanaged $path
}
