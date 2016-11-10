data = `cat go.rb | gzip -9 -f`
#script = "eval(`echo '#{data}' | gzip -d`)"
File.open('x', 'wb') do |f| 
  f << "# game by dab\ntail -n+3 x|gzip -d>y;ruby y\n"
  f << data 
end

