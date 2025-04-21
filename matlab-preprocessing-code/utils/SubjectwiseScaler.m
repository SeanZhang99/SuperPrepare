classdef SubjectwiseScaler
    %SUBJECTWISE_SCALER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        accumulate struct
        num_channel int32
        running logical
        scaling_factor double
    end
    
    methods
        function obj = SubjectwiseScaler(num_channel)
            arguments
                num_channel (1,1) double
            end
            %SUBJECTWISE_SCALER Construct an instance of this class
            %   Detailed explanation goes here
            obj.accumulate = struct("power",zeros(num_channel,1),"count",0);
            obj.num_channel = num_channel;
            obj.running = true;
        end
        
        function obj = update(obj,sample)
            arguments
                obj SubjectwiseScaler
                sample (:,:) double {ismatrix}
            end
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            if obj.running
                [t,c] = size(sample);
                assert(c==obj.num_channel);
                obj.accumulate.power = obj.accumulate.power + sum(sample.^2);
                obj.accumulate.count = obj.accumulate.count + t;
            else
                warning("Object does not operate on running mode. This means the object has collected all samples, and it can only" + ...
                    "scale the input or give the scaling factor")
            end
        end

        function [obj,scaling_factor] = get_scaling_factor(obj)
            obj.running = false;
            trimmed_mean = trimmean(obj.accumulate.power/obj.accumulate.count,20);
            scaling_factor = sqrt(median(trimmed_mean));
            obj.scaling_factor = scaling_factor;
        end

        function sample = rescale(obj,sample)
            if obj.running
                warning("This object is still collecting stats. No scaling is applied")
            else
                sample = sample ./ obj.scaling_factor;
            end
        end
    end
end

