require 'nokogiri'
require 'open-uri'
require 'csv'

require 'config'

# Defining constants

# URL to retrieve human-readable HTML
PUBMED_URL_BASE = 'http://www.ncbi.nlm.nih.gov/pubmed/?term='

# Retrieves XML from EPMC
EPMC_URL_BASE = 'http://www.ebi.ac.uk/europepmc/webservices/rest/search/query='
EPMC_URL_TAIL = '&resultType=core'

ALTMETRIC_URL_BASE = 'http://api.altmetric.com/v1/'

TEST_PMIDS = %w(
  18243253 18217840 18085873 18077465
  18070950 18061407 18059267 18039035
  18005474 17998437 17988420 17984343
  17980006 17973103 17959777 17955446
  17955208 17940814 17940553 17920642
  17919952 17907847 17897464 17713391
  17878762 17873222 17855376 17845723
  17826852 17805508 17676498 17729146
  17720888 17697477 17662150 17654599
  17636079 17618414 17608818 17584500
  17583990 17569739 17554342 17552381
  17542115 17533769 17526833 17519421
  17510272 17508343 17505772 17490403
  17488234 17484599)

test_pmid = TEST_PMIDS.sample

EPMC_ATTRIBUTES = {
  title: '//result//title',
  journal: '//result//journal//title',
  authors: '//result//authorstring',
  abstract: '//result//abstracttext'
}

ALTMETRIC_ATTRIBUTES = {
  # Fill this in!
}

def remove_tag(string)
  string.gsub(/\<[^\<]+\>/, '')
end

def get_epmc(pmid)
  # Add sanitisation
  url = EPMC_URL_BASE + pmid + EPMC_URL_TAIL
  epmc_xml = Nokogiri::HTML(open(url))
  article = {}
  EPMC_ATTRIBUTES.each do
     |key,value| article[key] = remove_tag(epmc_xml.xpath(value)[0].to_s)
  end
  return article
end

# Could generalise this as its structure is near identical to epmc. Hmm.

# def get_altmetric(pmid)
#   url = ALTMETRIC_URL_BASE + pmid + ALTMETRIC_API_KEY
#   altmetric_xml = Nokogiri::HTML(open(url))
#   article = []
#   ALTMETRIC_ATTRIBUTES.each do
#     |attribute| article << remove_tag(altmetric_xml.xpath(attribute[1])[0].to_s)
#   end
#   return article
# end



def csv_create(inputcsv, outputcsv)
  CSV.open(outputcsv, 'w') do |csv|
    headers = []
    pmids = []
    
    # Input headers
    EPMC_ATTRIBUTES.each { |header,value| headers << header.to_s }
    csv << headers
    
    # Input data
    pmids = CSV.read(inputcsv) # Is this inefficient?

    queries_per_second = 2
    pause = 1.0 / queries_per_second
    puts "Parsing #{pmids.length}.
    This will take at least #{pmids.length * pause} seconds."
    i = 0
    pmids.each do |pmid|
      row = []
      # Convert from hash to array, but referencing values
      get_epmc(pmid[0]).each { |k,v| row << v } 
      csv << row
      sleep pause
      i += 1
      puts "#{i} / #{pmids.length} complete. Approximately
      #{((pmids.length - i) * pause).round} seconds remain" if i % 5 == 0
    end
    puts 'Task complete!'
  end
end

sample_abstract = "Memory in autism spectrum disorder (ASD) is characterised by greater difficulties with recall rather than recognition and with a diminished use of semantic or associative relatedness in the aid of recall. Two experiments are reported that test the effects of item-context relatedness on recall and recognition in adults with high-functioning ASD (HFA) and matched typical comparison participants. In both experiments, participants studied words presented inside a red rectangle and were told to ignore context words presented outside the rectangle. Context words were either related or unrelated to the study words. The results showed that relatedness of context enhanced recall for the typical group only. However, recognition was enhanced by relatedness in both groups of participants. On a behavioural level, these findings confirm the Task Support Hypothesis [Bowler, D. M., Gardiner, J. M., &amp; Berthollier, N. (2004). Source memory in Asperger's syndrome. Journal of Autism and Developmental Disorders, 34, 533-542], which states that individuals with ASD will show greater difficulty on memory tests that provide little support for retrieval. The findings extend this hypothesis by showing that it operates at the level of relatedness between studied items and incidentally encoded context. By showing difficulties in memory for associated items, the findings are also consistent with conjectures that implicate medial temporal lobe and frontal lobe dysfunction in the memory difficulties of individuals with ASD."

# sample_abstract = get_epmc(test_pmid)[:abstract].to_s

# Find the hypothesis sentence

# Check it for a list of keywords

POSITIVE_INDICATORS = %w(support prove confirm extend)
CONFIRMERS = Regexp.union(POSITIVE_INDICATORS)

# Vary these keywords to support present, past and future tenses?

# Check for negation

NEGATIVE_INDICATORS = %w(un dis not\ )
NEGATORS = Regexp.union(NEGATIVE_INDICATORS)

sentence_regex = /(?:\.|\?|\!)(?= [^a-z]|$|\n)/
# Need to solve the problem of initialed name references. This might be too strict:
strict_sentence_regex = /(?<!\s\w|\d\))(?:\.|\?|\!)(?= [^a-z]|$|\n)/


# puts sample_abstract.class

# puts "Hypothesis sentence start: #{sample_abstract =~ sentence_regex}"

# Outputs array 
def extract_hypotheses(hypothesis, regex)
  hypothesis.split(regex).select{ |s| s.downcase[/hypoth/] }
end

test_hypotheses = extract_hypotheses(sample_abstract, strict_sentence_regex)

def hypothesis_tester (hypothesis)
  hypothesis.downcase!
  hypothesis[CONFIRMERS]
end

# puts "unconfirm"[NEGATORS]

test_hypotheses = extract_hypotheses(sample_abstract, strict_sentence_regex)


# test_hypotheses.each do
#   |h| 
#   puts "Testing hypothesis: #{h}"
#   puts hypothesis_tester(h)
# end

# puts sample_abstract

# puts sample_abstract[CONFIRMERS]

# Need a way of checking the sentence after for confirmed, etc.

# puts get_epmc(test_pmid)
# 
# csv_create('test_pmids.csv', 'test4.csv')