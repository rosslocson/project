package email

import (
	"bytes"
	"crypto/rand"
	"fmt"
	"html/template"
	"log"
	"math/big"
	"net/smtp"
	"os"
	"strings"
)

const registerEmailHTML = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>InternSpace Account Verification</title>
</head>
<body style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; line-height: 1.6; background-color: #f4f4f4; margin: 0; padding: 20px;">
  <table width="100%" border="0" cellspacing="0" cellpadding="0" style="max-width: 600px; margin: 0 auto;">
    <tr>
      <td style="background-color: #120205; color: #ffffff; padding: 40px 30px; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.2);">
        <table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
            <td style="width: 40px; height: 2px; background-color: #ffffff; margin-bottom: 20px;"></td>
            <td></td>
          </tr>
          <tr>
            <td colspan="2" style="padding-bottom: 10px;">
              <h2 style="color: #ffffff; font-size: 24px; margin: 0; font-weight: 600; letter-spacing: 1px;">ACCOUNT VERIFICATION</h2>
            </td>
          </tr>
          <tr>
            <td colspan="2" style="padding-bottom: 30px;">
              <p style="color: #d1d5db; font-size: 15px; margin: 0;">Welcome to the InternSpace galaxy! You are just one step away from setting up your dashboard and tracking your OJT hours. To complete your registration, please enter the verification code below. Do not share this code with anyone.</p>
            </td>
          </tr>
          <tr>
            <td colspan="2" style="text-align: center; background-color: #00022E; padding: 35px 20px; border-radius: 8px; margin: 30px 0;">
              <p style="color: #f3f4f6; margin: 0 0 10px 0; font-size: 14px; text-transform: uppercase; letter-spacing: 1px;">Verification Code</p>
              <div style="font-size: 42px; font-weight: bold; letter-spacing: 12px; font-family: monospace; color: #ffffff; margin: 15px 0;">{{.OTP}}</div>
              <p style="font-size: 12px; color: #d1d5db; margin: 10px 0 0 0;">Expires in 5 minutes</p>
            </td>
          </tr>
          <tr>
            <td colspan="2" style="text-align: center; padding-bottom: 40px;">
              <p style="font-size: 13px; color: #9ca3af; margin: 0;">If you didn't attempt to create an account, please ignore this email.</p>
            </td>
          </tr>
          <tr>
            <td colspan="2" style="border-top: 1px solid rgba(255,255,255,0.1); padding-top: 20px;">
              <p style="font-size: 12px; color: #9ca3af; margin: 0; text-align: left;">© InternSpace</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
`

type TemplateData struct {
	OTP string
}

func GenerateSecureOTP() (string, error) {
	max := big.NewInt(1000000)
	n, err := rand.Int(rand.Reader, max)
	if err != nil {
		return "", err
	}
	otp := fmt.Sprintf("%06d", n.Int64())
	log.Println("Generated Registration OTP:", otp)
	return otp, nil
}

func SendTestRegistrationEmail(toEmail string) error {
	otp, err := GenerateSecureOTP()
	if err != nil {
		return err
	}
	return SendRegistrationEmail(toEmail, otp)
}

func SendRegistrationEmail(recipientEmail, otpCode string) error {
	from := "internspace123@gmail.com"
	password := os.Getenv("SMTP_PASSWORD")
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")

	if from == "" || password == "" {
		return fmt.Errorf("SMTP_EMAIL or SMTP_PASSWORD not set")
	}

	if smtpHost == "" {
		smtpHost = "smtp.gmail.com"
	}
	if smtpPort == "" {
		smtpPort = "587"
	}

	log.Printf("📧 Email config loaded: SMTP_HOST=%s:%s, fixed sender=internspace123@gmail.com, Password set=%v", smtpHost, smtpPort, password != "")

	auth := smtp.PlainAuth("", from, password, smtpHost)

	t, err := template.New("register").Parse(registerEmailHTML)
	if err != nil {
		return err
	}

	var body bytes.Buffer

	headers := "From: InternSpace <" + from + ">\r\n" +
		"To: " + recipientEmail + "\r\n" +
		"Subject: Welcome to InternSpace - Verify Your Account\r\n" +
		"MIME-version: 1.0;\r\n" +
		"Content-Type: text/html; charset=\"UTF-8\"\r\n\r\n"

	body.Write([]byte(headers))

	err = t.Execute(&body, TemplateData{OTP: otpCode})
	if err != nil {
		return err
	}

	err = smtp.SendMail(
		smtpHost+":"+smtpPort,
		auth,
		from,
		[]string{recipientEmail},
		body.Bytes(),
	)

	if err != nil {
		errStr := err.Error()
		switch {
		case strings.Contains(errStr, "535"):
			log.Printf("🚫 SMTP AUTH FAILED to %s: Invalid app password - https://myaccount.google.com/apppasswords", recipientEmail)
		case strings.Contains(errStr, "connection refused") || strings.Contains(errStr, "dial tcp"):
			log.Printf("🔌 SMTP CONNECTION FAILED to %s: Check SMTP_HOST:%s running/port open", recipientEmail, smtpHost+":"+smtpPort)
		case strings.Contains(errStr, "timeout"):
			log.Printf("⏱️ SMTP TIMEOUT to %s: Network/firewall issue", recipientEmail)
		default:
			log.Printf("📧 SMTP ERROR to %s: %v", recipientEmail, err)
		}
		return fmt.Errorf("failed to send registration email to %s: %w", recipientEmail, err)
	}
	log.Printf("✅ REGISTRATION EMAIL SENT to %s (OTP hidden)", recipientEmail)
	return nil
}