#######
#
# This file will be run on every deploy, so make sure the changes here are non-destructive
#
#######

departments = [
  { :name => 'Attorney General\'s Office',
    :website_url => 'http://www.attorneygeneral.gov.uk',
    :description => '<p>The Attorney General and the Solicitor General have three main functions: chief legal advisers to the government; criminal justice ministers (alongside ministers in the Home Office and the Ministry of Justice); and guardians of the public interest.</p>
<p>The Attorney General and Solicitor General have overall responsibility for the Treasury Solicitor; superintend the Crown Prosecution Service (CPS) with the Revenue &amp; Customs Prosecution Office (RCPO) and the Serious Fraud Office; and have responsibility for HM Crown Prosecution Service Inspectorate and sponsor the National Fraud Authority (NFA).</p>'
  },
  { :name => 'Cabinet Office',
    :website_url => 'http://www.cabinetoffice.gov.uk',
    :description => '<p>The Cabinet Office sits at the centre of government and, with the Treasury, provides the government\'s co-ordination function. The Cabinet Office has an overarching purpose of making government work better and more efficiently. The Department has three core functions that enable it to achieve this overarching purpose:</p>
<dl>
  <dt>Supporting the Prime Minister and Deputy Prime Minister -</dt>
  <dd>to define and deliver the government\'s objectives, implement political and constitutional reform, and drive forward from the centre particular cross-departmental priority issues such as public service improvement, social exclusion, the Third Sector;</dd>
  <dt>Supporting the Cabinet -</dt>
  <dd>to drive the coherence, quality and delivery of policy and operations across departments;
  <dt>Strengthening the Civil Service -</dt>
  <dd>to ensure the civil service is organised effectively and efficiently and has the capability in terms of skills, values and leadership to deliver the government\'s objectives, including ensuring value for money to the taxpayer. Working with the Treasury to drive efficiency and reform across the public sector.</dd>
</dl>'
  },
  { :name => 'Department for Business, Innovation and Skills',
    :website_url => 'http://www.bis.gov.uk',
    :description => '<p>The Department for Business, Innovation and Skills aims to build a dynamic and competitive UK economy by: creating the conditions for business success; promoting innovation, enterprise and science and giving everyone the skills and opportunities to succeed. The Department will foster world-class universities and promote an open global economy.</p>'
  },
  { :name => 'Department for Communities and Local Government',
    :website_url => 'http://www.communities.gov.uk',
    :description => '<p>Communities and Local Government sets policy on local government, housing, urban regeneration, planning and fire and rescue. We have responsibility for all race equality and community cohesion related issues in England and for building regulations and fire safety.</p>'
  },
  { :name => 'Department for Culture, Media and Sport',
    :website_url => 'http://www.culture.gov.uk',
    :description => '<p>DCMS is the Department responsible for the 2012 Olympic Games and Paralympic Games, and we help drive the Digital Economy. Our aim is to improve the quality of life for all through cultural and sporting activities, to support the pursuit of excellence and to champion the tourism, creative and leisure industries.</p>'
  },
  { :name => 'Department for Education',
    :website_url => 'http://www.education.gov.uk',
    :description => '<p>The Department for Education is responsible for education and children\'s services.</p>'
  },
  { :name => 'Department for Energy and Climate Change',
    :website_url => 'http://www.decc.gov.uk',
    :description => '<p>The Department of Energy and Climate Change brings together energy policy and climate change mitigation policy.</p>'
  },
  { :name => 'Department for Environment, Food and Rural Affairs',
    :website_url => 'http://www.defra.gov.uk',
    :description => '<p>The government believes that we need to protect the environment for future generations, make our economy more environmentally sustainable, and improve our quality of life and well-being. We also believe that much more needs to be done to support the farming industry, protect biodiversity and encourage sustainable food production.</p>'
  },
  { :name => 'Department for International Development',
    :website_url => 'http://www.dfid.gov.uk',
    :description => '<p>The Department for International Development (DFID) leads the government\'s work to reduce poverty reduction and achieve the Millennium Development Goals. DFID funds UK development programmes in developing countries, and also channels money through international agencies to reduce poverty.</p>'
  },
  { :name => 'Department for Transport',
    :website_url => 'http://www.dft.gov.uk',
    :description => '<p>The Department creates the strategic framework for transport services, which are delivered through a wide range of public and private sector bodies including its own executive agencies. DfT often works in partnership, funding the provision and maintenance of infrastructure, subsidising services and fares on social grounds, and setting regulatory standards, especially for safety, accessibility and environmental impact.</p>'
  },
  { :name => 'Department for Work and Pensions',
    :website_url => 'http://www.dwp.gov.uk',
    :description => '<p>The Department for Work and Pensions (DWP) is responsible for delivering support and advice through a modern network of services to people of working age, employers, pensioners, families and children and disabled people. Its key aims are to help its customers become financially independent and to help reduce child poverty.</p>'
  },
  { :name => 'Department of Health',
    :website_url => 'http://www.dh.gov.uk/en',
    :description => '<p>The aim of the Department of Health (DH) is to improve the health and well-being of people in England.</p>'
  },
  { :name => 'Foreign and Commonwealth Office',
    :website_url => 'http://www.fco.gov.uk/en',
    :description  => '<p>The Foreign and Commonwealth Office works to promote the interests of the United Kingdom and to contribute to a strong world community.</p>'
  },
  { :name => 'Her Majesty\'s Treasury',
    :website_url => 'http://www.hm-treasury.gov.uk',
    :description => '<p>HM Treasury is the department responsible for formulating and putting into effect the UK government\'s financial and economic policy. The Treasury\'s overall aim is to raise the rate of sustainable growth, and achieve rising prosperity, through creating economic and employment opportunities for all.</p>'
  },
  { :name => 'Home Office',
    :website_url => 'http://www.homeoffice.gov.uk',
    :description => '<p>The Home Office leads a national effort to protect the public from terror, crime and anti-social behaviour. We secure our borders and welcome legal migrants and visitors. We safeguard identity and citizenship. We help build the security, justice and respect that enable people to prosper in a free and tolerant society.</p>
<p>Includes the Government Equalities Office, the department responsible for equalities legislation and policy in the UK. GEO is responsible for the government’s overall strategy and priorities on equality issues and aims to improve equality and reduce discrimination and disadvantage for all, at work, in public and political life, and in people’s life chances.</p>'
  },
  { :name => 'Ministry of Defence',
    :website_url => 'http://www.mod.uk',
    :description => '<p>The aim of the Ministry of Defence and the Armed Forces is: to deliver security for the people of the United Kingdom and the Overseas Territories by defending them, including against terrorism; and to act as a force for good by strengthening international peace and stability.</p>'
  },
  { :name => 'Ministry of Justice',
    :website_url => 'http://www.justice.gov.uk',
    :description => '<p>The Ministry of Justice (MoJ) is headed by the Secretary of State for Justice who is responsible for improvements to the justice system so that it better serves the public. He is also responsible for some areas of constitutional policy (those not covered by the Deputy Prime Minister). Priorities for the Department are to reduce re-offending and protect the public, to provide access to justice, to increase confidence in the justice system, and uphold people\'s civil liberties. The Secretary of State is the Government Minister responsible to Parliament for the judiciary, the court system and prisons and probation.</p>'
  },
  { :name => 'Northern Ireland Office',
    :website_url => 'http://www.nio.gov.uk',
    :description => '<p>The role of the Northern Ireland Office (NIO) is to maintain and support the devolution settlement flowing from the Good Friday and St Andrews Agreements and the devolution of criminal justice and policing to the Northern Ireland Assembly. The department retains responsibility for a range of reserved and excepted policy matters, including electoral law, human rights and certain aspects of equality; and for some elements of security including national security.</p>'
  },
  { :name => 'Office of the Leader of the House of Commons',
    :website_url => 'http://www.commonsleader.gov.uk',
    :description => '<p>The Office of the Leader of the House of Commons is responsible for the arrangement of government business in the House of Commons and for planning and supervising the government\'s legislative programme. The Leader upholds the rights and privileges of the House and acts as a spokesperson for the government as a whole.</p>'
  },
  { :name => 'Scotland Office',
    :website_url => 'http://www.scotlandoffice.gov.uk',
    :description => '<p>The Scotland Office, headed up by the Secretary of State for Scotland, is part of the Ministry of Justice, based in Whitehall, London. The Office\'s key roles are to represent Scotland\'s interests at Westminster and act as guardian to the Devolution Settlement.</p>'
  },
  { :name => 'Wales Office',
    :website_url => 'http://www.walesoffice.gov.uk',
    :description => '<p>The role of the Secretary of State for Wales and the Wales Office is to promote the devolution settlement for Wales, to promote the interests of Wales in policy formulation by the government, to promote government policies in Wales, to steer through Parliament legislation giving specific powers to the National Assembly for Wales, to operate the constitutional settlement under the Government of Wales Act 2006, to undertake Parliamentary business, and to deal with Royal matters.</p>'
  }
]

departments.each do |department|
  d = Department.find_or_initialize_by_name(department[:name])
  if d.new_record?
    d.update_attributes!(department)
  end
end
