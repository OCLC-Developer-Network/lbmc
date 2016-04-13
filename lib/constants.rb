# Copyright 2016 OCLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module LBMC

  ATOM_WRAPPED_MARC_MIMETYPE = 'application/atom+xml;content="application/vnd.oclc.marc21+xml"'
  MARC_XML_MIMETYPE = 'application/vnd.oclc.marc21+xml'
  
  SCRIPT_CODES = 
    {
      "Armenian" => "Armn",
      "Bengali" => "Beng",
      "Devanagari" => "Deva",
      "Ethiopic" => "Ethi",
      "Syriac" => "Syrc",
      "Tamil" => "Taml",
      "Thai" => "Thai",
      "Latin" => "(B",
      "CJK" => "$1",
      "Hebrew" => "(2",
      "Greek" => "(S",
      "ARABIC_BAS" => "(3",
      "ARABIC_EXT" => "(4",
      "CYRILLIC_BAS" => "(N",
      "CYRILLIC_EXT" => "(Q",
      "CYRILLIC_NONMARC" => "Cyrl"
    }
    
  NONMARC_LANGUAGES =  
    [ 
      "Armenian",
      "Bengali",
      "Devanagari",
      "Ethiopic",
      "Greek",
      "Hebrew",
      "Syriac",
      "Tamil",
      "Thai"
    ]
    
  SUPPORTED_LANGUAGES =  
    [ 
      "Arabic",
      "Armenian",
      "Bengali",
      #"Common",
      "Cyrillic",
      "Devanagari",
      "Ethiopic",
      "Greek",
      "Han",
      "Hangul",
      "Hebrew",
      "Hiragana",
      "Katakana",
      "Latin",
      "Syriac",
      "Tamil",
      "Thai"
    ]
    
  LANGUAGES = 
    {
      "Arabic" => /\p{Arabic}/, 
      "Armenian" => /\p{Armenian}/, 
      "Balinese" => /\p{Balinese}/, 
      "Bengali" => /\p{Bengali}/, 
      "Bopomofo" => /\p{Bopomofo}/, 
      "Braille" => /\p{Braille}/, 
      "Buginese" => /\p{Buginese}/, 
      "Buhid" => /\p{Buhid}/, 
      "Canadian_Aboriginal" => /\p{Canadian_Aboriginal}/, 
      "Carian" => /\p{Carian}/, 
      "Cham" => /\p{Cham}/, 
      "Cherokee" => /\p{Cherokee}/, 
      #"Common" => /\p{Common}/, 
      "Coptic" => /\p{Coptic}/, 
      "Cuneiform" => /\p{Cuneiform}/, 
      "Cypriot" => /\p{Cypriot}/, 
      "Cyrillic" => /\p{Cyrillic}/, 
      "Deseret" => /\p{Deseret}/, 
      "Devanagari" => /\p{Devanagari}/, 
      "Ethiopic" => /\p{Ethiopic}/, 
      "Georgian" => /\p{Georgian}/, 
      "Glagolitic" => /\p{Glagolitic}/, 
      "Gothic" => /\p{Gothic}/, 
      "Greek" => /\p{Greek}/, 
      "Gujarati" => /\p{Gujarati}/, 
      "Gurmukhi" => /\p{Gurmukhi}/, 
      "Han" => /\p{Han}/, 
      "Hangul" => /\p{Hangul}/, 
      "Hanunoo" => /\p{Hanunoo}/, 
      "Hebrew" => /\p{Hebrew}/, 
      "Hiragana" => /\p{Hiragana}/, 
      "Inherited" => /\p{Inherited}/, 
      "Kannada" => /\p{Kannada}/, 
      "Katakana" => /\p{Katakana}/, 
      "Kayah_Li" => /\p{Kayah_Li}/, 
      "Kharoshthi" => /\p{Kharoshthi}/, 
      "Khmer" => /\p{Khmer}/, 
      "Lao" => /\p{Lao}/, 
      "Latin" => /\p{Latin}/, 
      "Lepcha" => /\p{Lepcha}/, 
      "Limbu" => /\p{Limbu}/, 
      "Linear_B" => /\p{Linear_B}/, 
      "Lycian" => /\p{Lycian}/, 
      "Lydian" => /\p{Lydian}/, 
      "Malayalam" => /\p{Malayalam}/, 
      "Mongolian" => /\p{Mongolian}/, 
      "Myanmar" => /\p{Myanmar}/, 
      "New_Tai_Lue" => /\p{New_Tai_Lue}/, 
      "Nko" => /\p{Nko}/, 
      "Ogham" => /\p{Ogham}/, 
      "Ol_Chiki" => /\p{Ol_Chiki}/, 
      "Old_Italic" => /\p{Old_Italic}/, 
      "Old_Persian" => /\p{Old_Persian}/, 
      "Oriya" => /\p{Oriya}/, 
      "Osmanya" => /\p{Osmanya}/, 
      "Phags_Pa" => /\p{Phags_Pa}/, 
      "Phoenician" => /\p{Phoenician}/, 
      "Rejang" => /\p{Rejang}/, 
      "Runic" => /\p{Runic}/, 
      "Saurashtra" => /\p{Saurashtra}/, 
      "Shavian" => /\p{Shavian}/, 
      "Sinhala" => /\p{Sinhala}/, 
      "Sundanese" => /\p{Sundanese}/, 
      "Syloti_Nagri" => /\p{Syloti_Nagri}/, 
      "Syriac" => /\p{Syriac}/, 
      "Tagalog" => /\p{Tagalog}/, 
      "Tagbanwa" => /\p{Tagbanwa}/, 
      "Tai_Le" => /\p{Tai_Le}/, 
      "Tamil" => /\p{Tamil}/, 
      "Telugu" => /\p{Telugu}/, 
      "Thaana" => /\p{Thaana}/, 
      "Thai" => /\p{Thai}/, 
      "Tibetan" => /\p{Tibetan}/, 
      "Tifinagh" => /\p{Tifinagh}/, 
      "Ugaritic" => /\p{Ugaritic}/, 
      "Vai" => /\p{Vai}/, 
      "Yi" => /\p{Yi}/
    }


end