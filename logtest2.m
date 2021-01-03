% logtest 2

clear all;
available=true;
ready=true;
of_datagrams_avail=0;
% fileID = fopen('sig.txt','w');
udp_elm = udpport("datagram", "LocalPort", 54638);
flush(udp_elm);
% callback_handle=@write_new_line;
% configureTerminator(udp_elm,"LF");
% %ok_write_status=write_new_line(fileID,udp_elm);
% while udp_elm.NumDatagramsAvailable~=0
while available==true
        if udp_elm.NumDatagramsAvailable>=3000
            datagrams = read(udp_elm,udp_elm.NumDatagramsAvailable,"uint8");
%             fprintf('datagram\n');
            flush(udp_elm);
%             data8=zeros(length(datagrams));
            for datagram_select=1:length(datagrams)
                data8(datagram_select,:)=uint8(datagrams(datagram_select).Data);
                timestamp(datagram_select,:)=swapbytes(typecast(data8(datagram_select,5:8),'uint32'));
                sample_raw(datagram_select,:)=swapbytes(typecast(data8(datagram_select,3:4),'uint16'));
                seq_number(datagram_select,:)=swapbytes(typecast(data8(datagram_select,1:2),'uint16'));
            end
            datagram_select=1;
            channel= bitand(0b0011000000000000, sample_raw(:,:));
            channel= channel/4096;
            channel= channel(:,:)+1;
            sample = bitand(0b1100111111111111, sample_raw(:,:));
            address_1=find(channel==1);
            address_2=find(channel==2);
            address_3=find(channel==3);
            %sample_plus_channel_plustimestamp=sortrows(cat(2,channel,sample,timestamp));
            %color_select(channel)
            timestamp_double=double(timestamp)*0.00000004;
            sample_double=double(sample)*5/4096;
            graph=plot(timestamp_double(address_1), sample_double(address_1),'red',timestamp_double(address_2), sample_double(address_2),'blue',timestamp_double(address_3), sample_double(address_3),'green');
            xlabel('Segundos');
            ylabel('Tensión');
            title('Captura desde UDP')
            legend('canal 1', 'canal 2', 'canal 3');
            %         configureCallback(udp_elm,"datagram",100,@write_new_line)
        %         datagrams = read(udp_elm,100,"uint8");
            
            
            available=false;
        end
       
end 


% configureCallback(udp_elm,"off")
clear udp_elm;
% fclose(fileID);