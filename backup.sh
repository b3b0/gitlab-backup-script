#!/bin/bash
webhook_url="https://discord.com/api/webhooks/123456"
backup_dir="/your/root/path"
backup_parent_dir="gitlab_backup_$(date +%Y%m%d_%H%M%S)"
backup_dir_path="$backup_dir/$backup_parent_dir"
mkdir -p "$backup_dir_path"

echo "Performing GitLab backup..."
sudo gitlab-backup create

if [ $? -eq 0 ]; then
    # Move the GitLab backup files to the new directory
    echo "Moving GitLab backup files to $backup_dir_path..."
    mv /var/opt/gitlab/backups/* "$backup_dir_path"

    if [ $? -eq 0 ]; then
        # Backup GitLab secrets
        echo "Backing up GitLab secrets..."
        sudo cp /etc/gitlab/gitlab-secrets.json "$backup_dir_path"

        if [ $? -eq 0 ]; then
            # Backup GitLab configuration file
            echo "Backing up GitLab configuration..."
            sudo cp /etc/gitlab/gitlab.rb "$backup_dir_path"

            if [ $? -eq 0 ]; then
                # Create a zip file of the parent directory
                echo "Creating zip file of the backup..."
                zip -r "$backup_dir/$backup_parent_dir.zip" "$backup_dir_path"

                if [ $? -eq 0 ]; then
                    echo "Backup completed successfully."

                    message_content="Backup completed successfully! Saved as $(echo $backup_dir_path)."
                else
                    message_content="Creating zip file failed."
                fi
            else
                message_content="Backing up GitLab configuration failed."
            fi
        else
            message_content="Backing up GitLab secrets failed."
        fi
    else
        message_content="Moving GitLab backup files failed."
    fi
else
    message_content="Backup process failed."
fi

payload="{
    \"content\": \"$message_content\"
}"

curl -H "Content-Type: application/json" -d "$payload" "$webhook_url"
