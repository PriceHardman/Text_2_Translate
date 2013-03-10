['twilio-ruby','openssl','bing_translator'].each {|x| require x}

class UsersController < ApplicationController

  def new
    @user = User.new
  end

def create
    @user = User.new(params[:user])
    if @user.save
      render text: "Thank you for signing up to Text 2 Translate. You will receive
                    an SMS shortly with instructions on how you can use Text 2 Translate."

    #start twilio api here
    account_sid = 'AC9d1f6d5df9a54f0c995e4e51290f607b'
    auth_token = '3558e5064f7d10f92d75d45a6f3f1111'

   # set up a client to talk to the Twilio REST API
    @client = Twilio::REST::Client.new account_sid, auth_token

    @client.account.sms.messages.create(
        :from => '14155992671',
        :to => @user.phone,
        :body => "Please text the message to translate in the following format: \'98508420 english french This will be translated.\' For help, text \'98508420 help\'" 
    )

    else
      render :new
    end
end

   def translate
   @message = params[:Body]
   render :text => "<Response><Sms> #{translate_text(@message)} </Sms></Response>", :content_type => "text/xml"
  end


   #translator = BingTranslator.new('YOUR_CLIENT_ID', 'YOUR_CLIENT_SECRET')
   #spanish = translator.translate 'Hello. This will be translated!', :from => 'en', :to => 'es'
   translator = BingTranslator.new('RubyTranslate','b23Kbt0semubZJRHJz0sFH0yfns+plDk/F9gTza0GKs=')
   @chinese = translator.translate 'Hello, world', :from => 'en', :to => 'zh-CHT'
   render :text => "<Response><Sms> #{translate_text(@message)} </Sms></Response>", :content_type => "text/xml"
   end

  private
def language_name_to_code(input)

  #Languages are fed into the Bing Translation API via a two or three letter abbreviation, as seen in the hash below.
  #This method takes either a language code or full name and returns its counterpart.
  codes = {
'ar' =>  'arabic',
'bg' =>  'bulgarian',
'ca' =>  'catalan',
'zh-CHS' =>  'chinese (simplified)',
'zh-CHS' =>  'simplified chinese',
'zh-CHS' =>  'chinese', #an input of 'chinese' defaults to simplified characters.
'zh-CHT' =>  'chinese (traditional)',
'zh-CHT' =>  'traditional chinese',
'cs' =>  'czech',
'da' =>  'danish',
'nl' =>  'dutch',
'en' =>  'english',
'et' =>  'estonian',
'fa' =>  'farsi',
'fa' =>  'persian',
'fi' =>  'finnish',
'fr' =>  'french',
'de' =>  'german',
'el' =>  'greek',
'ht' =>  'haitian creole',
'he' =>  'hebrew',
'hi' =>  'hindi',
'hu' =>  'hungarian',
'id' =>  'indonesian',
'it' =>  'italian',
'ja' =>  'japanese',
'ko' =>  'korean',
'lv' =>  'latvian',
'lt' =>  'lithuanian',
'mww' => 'hmong daw',
'mww' => 'hmong',
'no' =>  'norwegian',
'pl' =>  'polish',
'pt' =>  'portuguese',
'ro' =>  'romanian',
'ru' =>  'russian',
'sk' =>  'slovak',
'sl' =>  'slovenian',
'es' =>  'spanish',
'sv' =>  'swedish',
'th' =>  'thai',
'tr' =>  'turkish',
'uk' =>  'ukrainian',
'vi' =>  'vietnamese'}

#Determine if the input was a code. If it was, return it.
#If a full language name was passed, return the corresponding code
if codes.select{|code| code==input }.any? #if a valid code was passed
  return input
elsif (codes.invert).select{|language| language == input.downcase}.any? #if a valid language was passed, case insensitive
  return (codes.invert).select{|language| language==input.downcase}[input.downcase] #Return the code
else
  return nil
end

end

#if the user texts only the word "help", this will be sent back to them instead of a translation.
def help_text
  "To use Text 2 Translate, send a text formatted as follows: "+
  "\"98508420 <from language> <to language> <text you wish to translate>\"\n"+ 
  "For example:\"98508420 french english C'est la vie.\" Try as many languages as you want!"
end

def parse_raw_text(input)
  #This method parses the text of the SMS message.


  #The message has the structure:   "API_PIN   from_language   to_language   text_to_be_translated
  #            For example:   "98508420 english french Hello, world!"

  #First, parse the string of text into individual words in an array, using split
  words_array = input.split


  ### If the text consists only of "<API PIN> help", return instructions
  return help_text if words_array[2]=="help" 


  #For translation purposes, the text has three main parts: the from language, the to language, and the text to be translated.
  #Isolate the languages and covert them to their Bing API codes:
  from_language = language_name_to_code(words_array[1])
  to_language = language_name_to_code(words_array[2])

  #get the parts of the words array that contain the text to be translated.
  #Then, turn it back into plain text from an array, using inject. Finally, strip the string of trailing whitespace using lstrip.
  text_to_be_translated_array = words_array[3,words_array.length-1]
  text_to_be_translated = text_to_be_translated_array.inject(""){|sentence,word| sentence << (" "+word)}.lstrip!

#Return the results as a hash
{:from_language => from_language,:to_language => to_language, :text_to_be_translated => text_to_be_translated}

end

def translate_text(input) #this method takes a formatted string as input, and returns the translation.
  translator = BingTranslator.new('RubyTranslate',
                                  'b23Kbt0semubZJRHJz0sFH0yfns+plDk/F9gTza0GKs=') #instantiate the translator
  sms = parse_raw_text(input) #preprocess the text
  output = translator.translate sms[:text_to_be_translated], 
                                :from => sms[:from_language], 
                                :to => sms[:to_language]
  return output
end
