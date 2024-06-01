# Initialise git
git init
git add .
git commit -m "first commit"
git branch -M main
# Manually create new repo on Github
git remote add origin git@github.com:micherts/hosposure.com.au.git
git push -u origin main

# Update git **Note git workflow syncs to S3
git add .
git commit -m "renamed assets\email\<two images>"
git push origin master

#Clone Git repo
git clone git@github.com:micherts/awesome-landing-page.git
