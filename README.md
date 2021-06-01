hugo-pipeline-terraform
===

This is a sample project for building pipeline of Hugo site on AWS using terraform.

# Usage

1. create `main.tf` and `variables.tf`

    ```bash
    cp main.tf.sample main.tf
    ```
    
    ```bash
    cp variables.tf.sample variables.tf
    ```
    
2. plan

    ```bash
    terraform plan
    ```

3. apply

    ```bash
    terraform apply
    ```