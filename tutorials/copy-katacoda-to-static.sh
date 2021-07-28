#!/bin/zsh

cat > combo.md << EOF
# Kapp Controller Package Management Tutorial

Ready to get started? Make a katacoda account and take our interactive tutorial [here](www.todo.com), or spin up your favorite playground and follow the steps below.

EOF


for file in $(dirname $0)/katacoda/kapp-controller-package-management/*md; do
    echo $file | grep -v intro | grep -v finish | sed 's/.*step\([0-9]*\).*/#### Step \1/' >> combo.md
    cat $file | sed 's/{{.*}}//' >> combo.md
done

