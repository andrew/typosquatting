# frozen_string_literal: true

module Typosquatting
  module Algorithms
    class Misspelling < Base
      COMMON_MISSPELLINGS = {
        "accommodate" => %w[accomodate acommodate],
        "achieve" => %w[acheive],
        "acquire" => %w[aquire],
        "address" => %w[adress],
        "argument" => %w[arguement],
        "calendar" => %w[calender],
        "category" => %w[catagory],
        "commit" => %w[comit],
        "config" => %w[confg],
        "database" => %w[databse],
        "debug" => %w[debig],
        "environment" => %w[enviroment enviornment],
        "experience" => %w[experiance],
        "gauge" => %w[guage],
        "grammar" => %w[grammer],
        "independent" => %w[independant],
        "library" => %w[libary libraray],
        "license" => %w[licence lisense],
        "necessary" => %w[neccessary necessery],
        "occurrence" => %w[occurence occurrance],
        "parallel" => %w[paralel parrallel],
        "privilege" => %w[priviledge],
        "queue" => %w[que],
        "receive" => %w[recieve],
        "recommend" => %w[recomend reccommend],
        "reference" => %w[refrence referance],
        "separate" => %w[seperate],
        "successful" => %w[succesful succesfull],
        "async" => %w[asyc asnyc],
        "util" => %w[utl],
        "utils" => %w[utls utlis],
        "helper" => %w[hleper helpr],
        "client" => %w[clent cleint],
        "server" => %w[sever servre],
        "request" => %w[requst reuqest],
        "response" => %w[respnse responese],
        "parse" => %w[prase prse],
        "logger" => %w[loger logge],
        "handler" => %w[handlr hander],
        "manager" => %w[manger managr],
        "controller" => %w[controler controllr],
        "service" => %w[sevice servce],
        "module" => %w[modle moduel],
        "package" => %w[pakage packge],
        "python" => %w[pyhton pytohn],
        "ruby" => %w[rubu rby],
        "javascript" => %w[javscript javasript],
        "typescript" => %w[typscript tyepscript]
      }.freeze

      def generate(package_name)
        variants = []

        COMMON_MISSPELLINGS.each do |correct, misspellings|
          if package_name.include?(correct)
            misspellings.each do |misspelling|
              variants << package_name.gsub(correct, misspelling)
            end
          end

          misspellings.each do |misspelling|
            if package_name.include?(misspelling)
              variants << package_name.gsub(misspelling, correct)
            end
          end
        end

        variants.uniq
      end
    end
  end
end
