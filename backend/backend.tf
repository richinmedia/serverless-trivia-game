terraform {
  backend "remote" {
    organization = "richinmedia"

    workspaces {
      name = "serverless-trivia-game"
    }
  }
}