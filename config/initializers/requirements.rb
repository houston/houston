$:.unshift Rails.root.join("lib", "freight_train", "lib").to_s
$:.unshift Rails.root.join("lib", "lail_extensions", "lib").to_s
$:.unshift Rails.root.join("lib", "unfuddle", "lib").to_s

require 'freight_train'
require 'lail/core_extensions'
require 'unfuddle'
require 'unfuddle_dump'
require 'parallel_enumerable'
