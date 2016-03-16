def splitAndWrite(filename):
    myFile = open(filename);
    wordFreq = dict();

    for speech in myFile :
        word, count = speech.split("\t");
        wordFreq[word] = count;
        
    wordFile = open("autoCompleteWords.txt", "w");
    countFile = open("autoCompleteCounts.txt", "w");

    for word in wordFreq.keys():
        if(wordFreq[word] > 500000):
            wordFile.write(word + "\n");
            countFile.write(wordFreq[word])

    wordFile.close();
    countFile.close();

splitAndWrite("count_1w.txt");
