import subprocess
import os
import sys
import time
import logging

def findAllFiles(startdir):
	everthing = [x for x in os.walk(startdir)]
	files = []
	for tup in everthing:
		path = tup[0]
		for file in tup[2]:
			if ".lock" not in file:
				files.append(path + "/" + file)
	return files

def clean():
	os.chdir("..")
	subprocess.call(["make", "fclean"])
	subprocess.call(["rm", "-rf", "bin/dsfml", "dsfml", "bin"])

if __name__ == '__main__':
	subprocess.call(["git", "clone", "https://github.com/Jebbs/DSFML.git", "bin/dsfml"])
	subprocess.call(["rm", "-rf", "bin/dsfml/.git"])
	subprocess.call(["cp", "-rf", "bin/dsfml", "."])
	olddata = []
	oldnames = findAllFiles("dsfml")
	for file in oldnames:
		file = open(file, 'r')
		olddata.append(file.read())
		file.close()
	one = subprocess.call("make")
	if one != 0:
		print("Failed to make")
		clean()
		sys.exit(1)
	os.chdir("bin")
	key = "FUNFUNWITHABUNBUN"
	ot = time.time()
	for i in range(10):
		st = time.time()
		one = subprocess.call(["./coda", "-c", "-cl", "22", "-e", "-k", key, "dsfml"], stdout=subprocess.PIPE)
		if one != 0:
			print("Failed with exit code:" + str(one))
			clean()
			sys.exit(1)
		subprocess.call(["rm", "-rf", "dsfml-2.1.1"])
		two = subprocess.call(["./coda", "-d", "-u", "-k", key, "out.coda"])
		if two != 0:
			print("Failed with exit code:" + str(two))
			clean()
			sys.exit(1)
		newdata = []
		newnames = findAllFiles("dsfml-2.1.1")
		for file in newnames:
			file = open(file, 'r')
			newdata.append(file.read())
			file.close()
		for j in range(len(newnames)):
			if newnames[j] != oldnames[j] or newdata[j] != olddata[j]:
				print("Failed at: " + newnames[j])
				clean()
				sys.exit(1)
		logging.critical("took:" + str(time.time() - st) + " thats roughly " + str(60 / (time.time() - st)) + " per minute")
	print("Total time for encryption was: " + str(time.time() - ot) + " Average time for one iter: " + str(10 / (time.time() - ot)))
	ot = time.time()
	for i in range(10):
		st = time.time()
		one = subprocess.call(["./coda", "-c", "-cl", "22", "dsfml"], stdout=subprocess.PIPE)
		if one != 0:
			print("Failed with exit code:" + str(one))
			clean()
			sys.exit(1)
		subprocess.call(["rm", "-rf", "dsfml-2.1.1"])
		two = subprocess.call(["./coda", "-u", "out.coda"])
		if two != 0:
			print("Failed with exit code:" + str(two))
			clean()
			sys.exit(1)
		newdata = []
		newnames = findAllFiles("dsfml-2.1.1")
		for file in newnames:
			file = open(file, 'r')
			newdata.append(file.read())
			file.close()
		for j in range(len(newnames)):
			if newnames[j] != oldnames[j] or newdata[j] != olddata[j]:
				print("Failed at: " + newnames[j])
				clean()
				sys.exit(1)
		logging.critical("took:" + str(time.time() - st) + " thats roughly " + str(60 / (time.time() - st)) + " per minute")
	print("Total time for compression was: " + str(time.time() - ot) + " Average time for one iter: " + str(10 / (time.time() - ot)))
	clean()