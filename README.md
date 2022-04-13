# jpstudy

[![CI](https://github.com/jhunschejones/jpstudy/actions/workflows/ci.yml/badge.svg)](https://github.com/jhunschejones/jpstudy/actions/workflows/ci.yml)

### Overview
Amidst the indoor days of 2020 I began, like many others, to pursue a newfound passion. I couldn't pluck up the same interest in sourdough as many of my peers, so instead I began what would turn out to be one of the most epic adventures of my life: learning Japanese.

Not only have I enjoyed getting better at a language I've so long admired, I also discovered I was really enjoying the process of learning *how* I learn personally. I loved the quote from Gabriel Wyner's book that nobody gives you a language, you have to take it. Learning Japanese was different than other learning activities I had pursued thus far in that I was attempting to actively coerce my brain into thinking differently.

Naturally, as a software engineer by trade, I turned to technology tools to help aid momentum to my learning. A big tool that I still use to this day is the digital, spaced repetition flashcards app, Anki. In the process of making thousands of custom digital flashcards, I found plenty of opportunities to polish my workflow. Many of these started as Ruby scripts and some even evolved into small Rails apps.

A year into my language learning journey I realized that I could obtain my next level of productivity boosts only by beginning to combine my new tools into a platform that was easy to setup and use. Not only that, but a combined toolkit might one day be able to help other language learners as well! Thus was born jpstudy.

jpstudy is a Rails 7 web app that provides an online version of some of my favorite Japanese language study tools. These tools are designed to supplement existing online resources and make the process of building Anki decks easier and more enjoyable. Some key features include:

#### The word list
This is the first feature I built into jpstudy and it it serves several purposes. At the simplest level, it's where I keep track of all the words I want to learn. I can access it from anywhere and it's easy to import and export word lists. I can also search among words I've previously added to see if a word already exists or if I've added a different conjugation of a word before.

One level deeper, the word cards inside the word list help provide links out to external resources that I use while building Anki flashcards. This has helped cut down the time I spend shuffling through browser tabs every day and allowed me to focus more on the creative work of finding pneumonic images, audio recordings, and example sentences. Finally, the word list helps me track my progress, by watching how many cards I make a day. This helps me see if my current velocity will get me to a specific learning goal by the time I need to be there!

#### Next Kanji
I am a native English speaker, and thus was somewhat daunted by all the new characters I would need to learn in order to be able to read and write in Japanese. After learning the kana I took an opinionated approach to learning kanji by attempting learn the rough meaning of each new kanji when they show up in a word on my word list. This is different than simply memorizing the different pronunciations for each kanji all at once, and I rely on encountering different words that use the same kanji for different sounds to fill in the gaps. 

To make this process as smooth as possible, the "next kanji" tool helps me keep track of which kanji I've made flashcards for. With that information, it can look at my word list and tell me what kanji I should make cards for next. Similar to the word list, the kanji tracking also helps me set goals and estimate how long it will take me to reach a certain number of kanji.

#### Audio conversion
I love playing with new technology toys, so when I discovered Amazon Polly, I immediately dove in to the Japanese voices to see what I could make. To my surprise, both voices sound pretty decent! I found that the neural voice can sometimes sound more natural, but it's often a tossup between the two. My preference is still to find native speaker audio recordings, or have one of my iTalki teachers read my sentences, but in a pinch, a little Japanese computer voice has helped speed up my learning pace considerably. 

My caution for those hoping to use this tool is that you should be somewhat familiar with general Japanese pronunciation first so that you can confirm by ear whether a specific voice is reading your sentence in a way that sounds reasonably correct before you stick it on a flashcard and burn it into your brain 💡

#### Import + Export
I mentioned Gabriel Wyner earlier because he has been one of the most significant influences on the language learning system I've put together for myself. Those familiar with his company, Fluent Forever, may even be wondering a this point why I went through all this trouble rather than using their native app that appears to offer most, if not all of these features already. Honestly, that's a great question. Fluent Forever is an incredible app and makes me so excited for the future of language learning tools!

The only two reasons I was not able to take advantage of this app were that it was somewhat harder to add custom vocabulary sets and there was no "import" method for me to bring my large collection of already learned words over so that I didn't have to repeat myself. In order to rectify this issue for the words I was entering into jpstudy, I have been careful to include import and export functionality for all user content features. I want to be able to save off my data when I want to move on to another tool, or import large amounts of data if needed, without having to start agin from scratch. So that's what I built! You can import and export word and kanji lists in a snap, giving me flexibility and peace of mind for the future.

### Conclusion
If you've read this far and are interested in trying out the app, drop me a line. I'd love to talk in more depth about your study process and the tools you have been using. I continue to build jpstudy with myself as the target customer, but I'm certainly open to suggestions and feedback if you are also embarking on a Japanese language learning journey of your own and looking around for some tools to help out. ❤️ 
