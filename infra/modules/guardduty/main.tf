# GuardDuty Detector
resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
  
  tags = {
    Name        = "FF-guardduty"
    Environment = "production"
  }
}