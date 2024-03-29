library(tokenizers)
library(syuzhet)
library(dplyr)
library(tidyr)
library(readr)
library(stringi)
library(ngram)
library(quanteda)

corpus <- "SupremeCourtCorpusFinalEncoded"
the_dirs <- dir(corpus, pattern = ".Cleaned")
metadata <- NULL
long_result <- NULL

for(i in 1:length(the_dirs)) {
  justice_result <- NULL
  the_files <- dir(file.path(corpus, the_dirs[i]))
  for(x in 1:length(the_files)){
    text_v <- get_text_as_string(file.path(corpus, the_dirs[i], the_files[x]))
    # remove numbers
    # this could be the issue. Maybe the punctuation is removed and replaces with spaces
    text_v <- concatenate(tolower(gsub('[[:punct:] ]+',' ', text_v)))
    text_v <- gsub('[0-9]+', ' ', text_v)

    #Alternative way? :
    text_tokens <- tokens(text_v, what = "fastestword", remove_numbers = TRUE, remove_punct = TRUE)
    ngram_v <- tokens_ngrams(text_tokens, n = 2, concatenator = "_")
    # ngram_t <- table(as.list(ngram_v))
    ngram_t <- table(as.character(ngram_v))

    # raw token counts
    #ngram_rel_t <- data.frame(the_dirs[i], x, ngram_df, "N", stringsAsFactors = FALSE)
    # OR new:
    ngram_raw_df <- data.frame(the_dirs[i], x, ngram_t, "N", stringsAsFactors = FALSE)
    colnames(ngram_raw_df) <- c("Author", "Text_ID", "Ngram", "Count", "Type")
    ngram_df <- mutate(ngram_raw_df, Freq = Count/sum(Count))

    justice_result <- rbind(justice_result, ngram_df)

    # create a master file with metadata
    metadata <- rbind(metadata, data.frame(the_dirs[i], x, sum(ngram_df$Count), the_files[x]))

    # monitor progress. . .
    cat(the_dirs[i], "---", x, the_files[x], "\n")
  }
  long_result <- rbind(long_result, justice_result)
}
# this is the file I want to mutate332
temp_name <- paste("Ngram/RData/", "long_result", ".RData", sep="")
save(long_result, file=temp_name)


# add a column for gender and set all to male
metadata <- data.frame(metadata, gender="M", stringsAsFactors = F)
colnames(metadata) <- c("Author", "Text_ID", "NumPhrase","File_name", "gender")

# replace M with F for the two female justices
metadata[which(metadata$Author %in% c("GinsburgCleaned", "OConnorCleaned")), "gender"] <- "F"

# Check results
table(metadata$gender)


temp_name <- paste("Ngram/Data/metadata.RData", sep="")
save(metadata, file=temp_name)

# # Make wide dataframes
# long_form <- NULL
# rdata_files <- dir("Ngram/RData")
# for(i in 1:length(rdata_files)){
#   load(file.path("Ngram/RData", rdata_files[i]))
#   long_form <- rbind(long_form, long_result)
# }
# save(long_form, file="Ngram/Data/long_form.RData")
# 
# row.names(long_form) <- F
# 
# long_form <- df
# rownames(df) = make.names(df$ID, unique=TRUE)
# 
# load("Ngram/Data/long_form.RData")
# 
# # mutate to create a unique primary key "ID" for each document and to create a "Feature" column that prefixes each token with its token type based on the "type" column
# long_form <- mutate(long_form, ID=paste(Author, Text_ID, sep="_"), Feature=paste(Type, Ngram, sep="_"))
# 
# 
# # Convert from long form to wide form sparse matrix
# wide_relative_df <- select(long_form, ID, Feature, Freq) %>%
#   spread(Feature, Freq, fill = 0)
# 
# save(wide_relative_df, file="Ngram/Data/wide_relative_df.RData")
# rm(wide_relative_df)
# 
# # Repeat for raw counts instead of the relative frequencies
# wide_raw_df <- select(long_form, ID, Feature, Count) %>%
#   spread(Feature, Count, fill = 0)
# 
# save(wide_raw_df, file="Ngram/Data/wide_raw_df.RData")
# rm(wide_raw_df)
