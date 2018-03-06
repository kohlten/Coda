import subprocess
import os
import sys
import time
import logging

if __name__ == '__main__':
	if "coda" not in os.listdir("bin"):
		subprocess.call("make")
	play = open("bin/romeojil.txt")
	playText = play.read().split('\n')
	play.close()
	os.chdir("bin")
	key = "FUNFUNWITHABUNBUN"
	for i in range(10):
		st = time.time()
		one = subprocess.call(["./coda", "-c", "-en", "-k=" + key, "romeojil.txt"])
		if one != 0:
			print("Failed with exit code:" + str(one))
			sys.exit(1)
		subprocess.call(["rm", "romeojil.txt"])
		two = subprocess.call(["./coda", "-d", "-de", "-k=" + key, "out.coda"])
		if two != 0:
			print("Failed with exit code:" + str(two))
			sys.exit(1)
		new = open("romeojil.txt")
		newText = new.read().split('\n')
		new.close()
		for j in range(len(newText)):
			if newText[j] != playText[j]:
				print("Failed at: " + str(i) + " On sentence:\n" + newText[i] + "\n" + playText[i])
				sys.exit(1)
		#print i
		#if i % 10 == 0:
		logging.critical("took:" + str(time.time() - st) + " thats roughly " + str(60 / (time.time() - st)) + " per second")
	time.sleep(5)
	play = open("romeojil.txt", 'w')
	play.write('\n'.join(playText))
	play.close()
	os.chdir("..")
	subprocess.call(["make", "fclean"])
