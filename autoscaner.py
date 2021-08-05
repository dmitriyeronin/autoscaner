#!/usr/bin/python

import telebot
import schedule
import time
import subprocess

# Enter telegram bot id and chat id before start
bot = telebot.TeleBot('');
chat_id = ''

def scan_and_send():
    p = subprocess.Popen(["./autoscan.sh > /dev/null"], shell=True)
    p.wait()
    with open('report.txt', 'r') as file:
        report = file.read()
        bot.send_message(chat_id, report)

schedule.every().hour.do(scan_and_send)

while True:
    schedule.run_pending()
    time.sleep(60)
