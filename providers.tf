provider "aws" {
  alias = "Israel"
  region  = "il-central-1"
  profile = "${var.aws_profile}"
}

provider "aws" {
  alias = "EU"
  region  = "eu-central-1"
  profile = "${var.aws_profile}"
}

provider "aws" {
  alias = "US"
  region  = "us-east-1"
  profile = "${var.aws_profile}"
}

provider "aws" {
  region  = "eu-central-1"
  profile = "${var.aws_profile}"
}

