�m  
MODE v3.105 

$Requires CP/M 3.1 or MP/M
$GETDP.REL not linked into system
$�{U	� �{U4��sU1w	� � }�0�X|* �#^#V�"e 	�r�[�_�R�d��»�	� å�*:N����~���w���}~��g�N�~���w���}~��Xå!� ~��#"GO 	6 *G�� �+"G��~��#�a��{?�� 7�>2N*G��c�A�c�Q�c2�2�
2	2��AG��c�:�cx2O��� �`+��D�� �y�ʴ�¬#ʌ� �|~�ʛ�,ʛ� ¬�:P��cy�02P�;���r���D���S� �H�cG��c�T�cx2Q�;>SG��c�T���D���S�cx2R�;x2S�;~�0�c�:����0G~��7�,�7� �7�0�c�:�c��0Ox�����Gx2T��^�,�O� �;+�j��^� �O+�j�2N�>�����:P�ʃ�0! <=()��t �u:R�ʙ���/�ݶ�w:S�ʱ���/�ݶ�w:Q����D(�S(������������������:T����~!4 �� ���#��x������ݶ�w�D�!?�>�KC�[E�
���#�=�%��[C~#��?*e 	�r��f��:I  �
�k�^�
G!00	}�0�w> o"�
�
:N�ʈ�
	� �
	� *C��~¥##�~^	ʫq		� �		� �g	� ͪ��###�f���	���		� ��###�v���	���		� ��###�n�+�n#�
2
� 
�
	� ��##~��~(��!$_ ^#V�"�
�
	� �
:�
� �H	� k
	� �V#^��D� ��:�8	�^��� ��#�ͪ�:O*a �r_ ~2I���W *	O�fڃ"<2>>����>��>���+~�$>��*< �r:>���_ "C�! "E!?� ��!?:I�� �r"J�2L2M:L��E"Jd~#�$�)��)� �!�>�2L�E:MG����Ex2M+~#"J��!��[J�:L�:O< =�`�#��U%� ��*< ^#V�N#fi��à�à�à	à*	� Xà�
	� �{U�h
	� �The MODE utility is called in one of the following ways:

        MODE
Outputs HELP information

        MODE d:
Displays the present drive status to the user

        MODE d:arg1,arg2,arg3
Updates the present status and displays it. Valid arguments are:

        DS or SS = double or single sided
        DT, ST or HT = double (96 tpi), single (48 tpi), or half track
          half track is 48 tpi media in a 96 tpi drive.
        DD or SD = double or single density
        S6, S30, etc. = step rate in milliseconds
        MMS, Z37, Z37X etc. (media formats); the X implies extended format.

$Drive A: has a fixed configuration which cannot be determined by MODE.
$5.25 inch floppy
$8 inch floppy
$       Controller - $            Sides - 1
$            Sides - 2
$Recording Density - Single
$Recording Density - Double
$  Tracks per Inch - 48
$  Tracks per Inch - 96
$  Tracks per Inch - 48 tpi media in 96 tpi drive (R/O)
$      Format Type - $        Step Rate - $00 milliseconds
$            Drive - A: (  ) $PRESENT Configuration is:
$NEW Configuration is:
$Invalid command line or command line arguments.
$The requested format is invalid for the specified drive.
The complete configuration must be supplied
$A: does not exist.
$The driver module for A: is incompatible with MODE.
$ inoperative.
$Drive is specified but not linked - ERROR IN SYSTEM-
$ 6122030 3 61015                                                                    