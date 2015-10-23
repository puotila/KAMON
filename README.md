# KAMON
KAMON project code

1. Clone the repository: 
git clone git@github.com:puotila/KAMON.git

2. If you don't want to see all content of the repository but only selected folders,
   you can use "sparse-checkout".
   1) git config core.sparsecheckout true
   2) write a list of those folders or files, which you DO want to see, into 
      .git/info/sparse-checkout
      E.g. echo ppc/   > .git/info/sparse-checkout
           echo perl/ >> .git/info/sparse-checkout
   3) git read-tree -m -u HEAD (to update the view)
   To make that process easier you can also use this script:
     #!/bin/sh
     echo > .git/info/sparse-checkout
     for i in "$@"
     do
       echo "$i" >> .git/info/sparse-checkout
     done
     git read-tree -m -u HEAD
   Then, step 2) and 3) become:
   nameofthescript ppc/ perl/

   If you want to see ALL files again use
   nameofthescript '*'
   or put only an asterisk in .git/info/sparse-checkout

