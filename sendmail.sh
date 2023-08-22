/usr/sbin/sendmail -i -t -v << MSG_END
From: "Test" <test@hostname.com>
To: test-something@srv1.mail-tester.com
Subject: Hello mail-tester !
Return-Path: <test@hostname.com>

Hello this is a message sent using sendmail cli :)
MSG_END

/usr/bin/mailq