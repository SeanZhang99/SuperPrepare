function parts = split_camel_case(str)
% 在大写字母处分隔 camelCase 或 PascalCase 字符串
% 支持连续大写缩写，如 HTTP, XML
    
    % 模式说明：
    % [A-Z]?       可选的首字母大写（处理 camelCase 首字母小写）
    % [^A-Z]*      后续非大写字符（小写+数字）
    % (?=[A-Z]|$)  正向预查：后面紧跟大写字母或字符串结尾
    parts = regexp(str, '[A-Z]?[^A-Z]*', 'match');
    
    % 去掉空字符串元素
    parts = parts(~cellfun('isempty', parts));
end