clear

echo "kbld has 2 main features" | pv -qL 12
echo "  1 - resolves tags to SHAs of all images present in the input yaml" | pv -qL 12
echo "  2 - orchestrates the build of images and updates the input yaml accordingly" | pv -qL 12

echo "# Example of resolution of tags given the follow yaml" | pv -qL 12
echo "cat tag-resolution.yml" | pv -qL 12
cat tag-resolution.yml
echo ''
echo ''
sleep 2
echo "kbld will resolve nginx image to the correct SHA" | pv -qL 12
echo "kbld -f tag-resolution.yml" | pv -qL 12
kbld -f tag-resolution.yml
echo ''
echo ''
sleep 2

echo "In the output you can see that nginx was replaced by the full reference of the nginx image." | pv -qL 12
echo "This is very important to make sure we know what is the image that is being used in our pods" | pv -qL 12

echo "# Example of building images using the following yaml" | pv -qL 12
echo "cat orchestrate-build.yml" | pv -qL 12
cat orchestrate-build.yml
echo ''
echo ''
sleep 2

echo "kbld will build the image called simple-app-with-docker with docker buildx" | pv -qL 12
echo "and will build the image called simple-app-with-pack with pack \(buildpacks.io\)" | pv -qL 12

echo "kbld -f orchestrate-build.yml" | pv -qL 12
kbld -f orchestrate-build.yml
echo ''
echo ''

echo "kbld supports building using bazel, docker buildx, ko, buildkit CLI for kubectl and pack" | pv -qL 12
sleep 5