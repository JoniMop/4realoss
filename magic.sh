#!/bin/bash

hooks_dir=".git/hooks"

mkdir -p "$hooks_dir"

pre_push_hook="$hooks_dir/pre-push"
touch "$pre_push_hook"

cat << 'EOF' > "$pre_push_hook"
#!/bin/bash
ipfs_hash=$(ipfs add -r . --quieter)
echo "Added files to IPFS. IPFS hash: $ipfs_hash"
echo $ipfs_hash >> .ipfs_hashes
EOF

chmod +x "$pre_push_hook"

echo ".ipfs_hashes" >> .gitignore
echo ".gitx" >> .gitignore

git_add_script=".gitx"
touch "$git_add_script"

cat << 'EOF' > "$git_add_script"
#!/bin/bash
ipfs_hash=$(ipfs add -r . --quieter)
echo "Added files to IPFS. IPFS hash: $ipfs_hash"
echo $ipfs_hash >> .ipfs_hashes
EOF

chmod +x "$git_add_script"

if [[ "$OSTYPE" == "darwin"* ]]; then
    chflags hidden "$git_add_script"
fi

echo "Successfully used magic :) - Will proceed to delete magic.sh now"

rm magic.sh
